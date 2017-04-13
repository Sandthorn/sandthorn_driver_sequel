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
    let(:event_serializer) { -> (data) { YAML.dump(data) } }
    let(:event_deserializer) { -> (data) { YAML.load(data) } }
    let(:snapshot_serializer) { -> (data) { YAML.dump(data) } }
    let(:snapshot_deserializer) { -> (data) { YAML.load(data) } }
    let(:aggregate_access) { AggregateAccess.new(storage) }
    let(:event_access) { EventAccess.new(storage, event_serializer, event_deserializer) }
    let(:aggregate) { aggregate_access.register_aggregate(aggregate_id, "foo") }
    let(:access) { SnapshotAccess.new(storage, snapshot_serializer, snapshot_deserializer) }
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
    let(:snapshot_aggregate) { 
      aggregate #register the aggregate
      Struct::AggregateMock.new aggregate_id, 0
    }

    let(:snapshot_aggregate_2) { 
      Struct::AggregateMock.new aggregate_id, 2
    }

    describe "#find_by_aggregate_id" do
      it "returns the correct data" do
        access.record_snapshot(snapshot_aggregate)
        aggregate.update(aggregate_version: 1)
        snapshot = access.find_by_aggregate_id(aggregate.aggregate_id)
        expect(snapshot.data).to eql snapshot_aggregate
        
      end
    end

    describe "#record" do
      context "when the aggregate doesn't exist" do
        it "raises an error" do
          agg = Struct::AggregateMock.new "qux", 1
          expect { access.record_snapshot(agg) }.to raise_error(Errors::NoAggregateError)
        end
      end
      context "when the aggregate exists" do
        context "when no previous snapshot exists" do
          it "records the snapshot" do
            
            expect(access.find_by_aggregate_id(aggregate_id)).to be_nil
            access.record_snapshot(snapshot_aggregate)

            snapshot = access.find_by_aggregate_id(aggregate_id)
            expect(snapshot).to_not be_nil
            expect(snapshot.data).to eq(snapshot_aggregate)
            expect(snapshot.data.aggregate_version).to eq(0)
          end
        end
        context "when the snapshot isn't fresh" do
          context "when the versions match" do
            it "records a new snapshot" do
              expect(access.find_by_aggregate_id(aggregate_id)).to be_nil
              access.record_snapshot(snapshot_aggregate)
              event_access.store_events(aggregate, events)
              access.record_snapshot(snapshot_aggregate_2)

              snapshot = access.find_by_aggregate_id(aggregate_id)
              expect(snapshot).to_not be_nil
              expect(snapshot.data).to eq(snapshot_aggregate_2)
              expect(snapshot.data.aggregate_version).to eq(2)
            end
          end

        end
        
      end
    end

    it "can write and read snapshots" do
      
      snapshot_id = access.record_snapshot(snapshot_aggregate)
      snapshot = access.find(snapshot_id)
      
      expect(snapshot).to_not be_nil
      expect(snapshot.data).to eq(snapshot_aggregate)
      expect(snapshot)

    end

    def generate_uuid
      SecureRandom.uuid
    end
  end
end
