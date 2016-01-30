require 'spec_helper'

module SandthornDriverSequel
  describe SnapshotAccess do
    include EventStoreContext

    before do
      prepare_for_test
    end

    let(:context) { :test }
    let(:db) { Sequel.connect(event_store_url)}
    let(:aggregate_id) { generate_uuid }
    let(:storage) { Storage.new(db, :test) }
    let(:serializer) { -> (data) { YAML.dump(data) } }
    let(:deserializer) { -> (data) { YAML.load(data) } }
    let(:aggregate_access) { AggregateAccess.new(storage) }
    let(:event_access) { EventAccess.new(storage, serializer, deserializer) }
    let(:aggregate) { aggregate_access.register_aggregate(aggregate_id, "foo") }
    let(:access) { SnapshotAccess.new(storage) }
    let(:events) do
      [
          {
              aggregate_version: 1,
              event_name: "new",
              event_data: "new_data"
          },{
              aggregate_version: 2,
              event_name: "foo",
              event_data: "foo_data"
          }
      ]
    end

    describe "#find_by_aggregate_id" do
      it "returns the correct data" do
        aggregate = aggregate_access.register_aggregate(aggregate_id, "foo")
        access.record_snapshot(aggregate.aggregate_id, { aggregate_version: 0, event_data: "data" })
        aggregate.update(aggregate_version: 1)
        snapshot = access.find_by_aggregate_id(aggregate.aggregate_id)
        expected = {
            aggregate_table_id: aggregate.id,
            aggregate_version: 0,
            snapshot_data: "data",
            id: snapshot.id
        }
        expect(snapshot.values).to eq(expected)
      end
    end

    describe "#record" do
      context "when the aggregate doesn't exist" do
        it "raises an error" do
          expect { access.record_snapshot("qux", "data") }.to raise_error(Errors::NoAggregateError)
        end
      end
      context "when the aggregate exists" do
        context "when no previous snapshot exists" do
          it "records the snapshot" do
            aggregate_table_id = aggregate_access.register_aggregate(aggregate_id, "foo").id
            expect(access.find_by_aggregate_id(aggregate_id)).to be_nil
            access.record_snapshot(aggregate_id, { aggregate_version: 0, event_data: "data"})

            snapshot = access.find_by_aggregate_id(aggregate_id)
            expect(snapshot).to_not be_nil
            expect(snapshot.aggregate_table_id).to eq(aggregate_table_id)
            expect(snapshot.snapshot_data).to eq("data")
            expect(snapshot.aggregate_version).to eq(0)
          end
        end
        context "when the snapshot isn't fresh" do
          context "when the versions match" do
            it "records a new snapshot" do
              aggregate = aggregate_access.register_aggregate(aggregate_id, "foo")
              expect(access.find_by_aggregate_id(aggregate_id)).to be_nil
              access.record_snapshot(aggregate_id, { aggregate_version: 0, event_data: "data"})
              event_access.store_events(aggregate, events)
              access.record_snapshot(aggregate_id, { aggregate_version: 2, event_data: "other_data"})

              snapshot = access.find_by_aggregate_id(aggregate_id)
              expect(snapshot).to_not be_nil
              expect(snapshot.aggregate_table_id).to eq(aggregate.id)
              expect(snapshot.snapshot_data).to eq("other_data")
              expect(snapshot.aggregate_version).to eq(2)
            end
          end

          context "when the versions don't match" do
            it "raises an error" do
              aggregate = aggregate_access.register_aggregate(aggregate_id, "foo")
              aggregate.update(aggregate_version: 10)
              expect { access.record_snapshot(aggregate_id, snapshot_data) }.to raise_error
            end
          end
        end
        context "when the snapshot is fresh" do
          it "doesn't record a snapshot" do
            aggregate = aggregate_access.register_aggregate(aggregate_id, "foo")
            expect(access.find_by_aggregate_id(aggregate_id)).to be_nil
            access.record_snapshot(aggregate_id, { aggregate_version: 0, event_data: "data"})
            access.record_snapshot(aggregate_id, { aggregate_version: 0, event_data: "new_data"})
            snapshot = access.find_by_aggregate_id(aggregate_id)
            expect(snapshot.snapshot_data).to eq("data")
          end
        end
      end
    end

    it "can write and read snapshots" do
      snapshot_id = access.record_snapshot(aggregate.aggregate_id, { aggregate_version: 0, event_data: "data" })
      snapshot = access.find(snapshot_id)
      expect(snapshot).to_not be_nil
      expect(snapshot.snapshot_data).to eq("data")
      expect(snapshot)
    end

    def generate_uuid
      SecureRandom.uuid
    end
  end
end
