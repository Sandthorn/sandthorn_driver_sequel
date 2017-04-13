require 'spec_helper'

module SandthornDriverSequel
  describe EventAccess do
    include EventStoreContext

    before do
      prepare_for_test
    end

    let(:context) { :test }
    let(:db) { Sequel.connect(event_store_url)}
    let(:aggregate_id) { SecureRandom.uuid }
    let(:aggregate) do
      aggregate_access.register_aggregate(aggregate_id, "AggregateMock")
    end
    let(:storage) { Storage.new(db, :test) }
    let(:event_serializer) { -> (data) { YAML.dump(data) } }
    let(:event_deserializer) { -> (data) { YAML.load(data) } }
    let(:snapshot_serializer) { -> (data) { YAML.dump(data) } }
    let(:snapshot_deserializer) { -> (data) { YAML.load(data) } }
    let(:aggregate_access) { AggregateAccess.new(storage) }
    let(:snapshot_access) { SnapshotAccess.new(storage, snapshot_serializer, snapshot_deserializer)}
    let(:access) { EventAccess.new(storage, event_serializer, event_deserializer) }


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

    describe "#store_events" do

      it "handles both arrays and single events" do
        access.store_events(aggregate, events[0])
        events = access.find_events_by_aggregate_id(aggregate_id)
        expect(events.length).to eq(1)
      end

      it "adds timestamps to all events and associates them to the aggregate" do
        access.store_events(aggregate, events)
        events = access.find_events_by_aggregate_id(aggregate_id)
        expect(events.map(&:timestamp).all?).to be_truthy
      end

      it "updates the aggregate version" do
        access.store_events(aggregate, events)
        events = access.find_events_by_aggregate_id(aggregate_id)
        version = events.map(&:aggregate_version).max

        reloaded_aggregate = aggregate_access.find(aggregate.id)
        expect(reloaded_aggregate.aggregate_version).to eq(version)
      end

      context "when the aggregate version of an event is incorrect" do
        it "throws an error" do
          event = { aggregate_version: 100 }
          expect { access.store_events(aggregate, [event])}.to raise_error(Errors::ConcurrencyError)
        end
      end
    end

    describe "#find_events_by_aggregate_id" do
      context "when there are events" do
        before do
          access.store_events(aggregate, events)
        end
        let(:stored_events) { access.find_events_by_aggregate_id(aggregate.aggregate_id) }

        it "returns correct events" do
          expect(stored_events.map(&:aggregate_table_id)).to all(eq(aggregate.id))
          expect(stored_events.size).to eq(events.size)
          expect(stored_events).to all(respond_to(:merge))
        end
        it "returns events in correct order" do
          expect(stored_events.first[:aggregate_version] < stored_events.last[:aggregate_version]).to be_truthy
          expect(stored_events.first[:sequence_number] < stored_events.last[:sequence_number]).to be_truthy
        end
      end
    end

    describe "#after_snapshot" do
      it "returns events after the given snapshot" do
        access.store_events(aggregate, events.first)

        aggregate_struct = Struct::AggregateMock.new aggregate_id, events.first[:aggregate_version]

        snapshot_id = snapshot_access.record_snapshot(aggregate_struct)
        snapshot = snapshot_access.find(snapshot_id)

        access.store_events(aggregate, events.last)
        
        events = access.after_snapshot(snapshot)
        expect(events.count).to eq(1)
        expect(events.first[:event_data]).to eq("foo_data")
      end
    end

  end
end
