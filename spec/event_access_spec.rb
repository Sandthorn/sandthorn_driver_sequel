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
    let(:aggregate_access) { AggregateAccess.new(storage) }
    let(:access) { EventAccess.new(storage, event_serializer, event_deserializer) }


    let(:events) do
      [
        {
          aggregate_version: 1,
          event_name: "new",
          event_data: "new_data",
          event_metadata: nil
        },{
          aggregate_version: 2,
          event_name: "foo",
          event_data: "foo_data",
          event_metadata: nil
        },{
          aggregate_version: 3,
          event_name: "foo2",
          event_data: "foo_data2",
          event_metadata: nil
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

      context "when using after_aggregate_version" do
        before do
          access.store_events(aggregate, events)
        end

        # exclude the first event
        let(:stored_events) { access.find_events_by_aggregate_id(aggregate.aggregate_id, 1) }

        it "returns correct events" do
          expect(stored_events.map(&:aggregate_table_id)).to all(eq(aggregate.id))
          expect(stored_events.size).to eq(events.size-1)
          expect(stored_events).to all(respond_to(:merge))
        end

        it "returns events in correct order" do
          expect(stored_events.first[:aggregate_version] < stored_events.last[:aggregate_version]).to be_truthy
          expect(stored_events.first[:sequence_number] < stored_events.last[:sequence_number]).to be_truthy
        end

        it "should not return event with aggregate_version = 1" do
          expect(stored_events.first[:aggregate_version]).not_to eq(1)
        end
        
      end
    end

  end
end
