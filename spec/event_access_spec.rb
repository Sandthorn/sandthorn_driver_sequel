require 'spec_helper'

module SandthornDriverSequel
  describe EventAccess do
    include EventStoreContext
    let(:context) { :test }
    let(:db) { Sequel.connect(event_store_url)}
    let(:aggregate_id) { SecureRandom.uuid }
    let(:aggregate) do
      aggregate_access.register_aggregate(aggregate_id, "foo")
    end
    let(:storage) { Storage.new(db, :test) }
    let(:aggregate_access) { AggregateAccess.new(storage) }
    let(:access) { EventAccess.new(storage) }

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
      it "adds timestamps to all events and associates them to the aggregate" do
        access.store_events(aggregate, events)
        events = access.find_events_by_aggregate_id(aggregate_id)
        expect(events.map(&:timestamp).map(&:nil?).any?).to be_falsey
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
        it "returns correct events" do
          access.store_events(aggregate, events)
          stored_events = access.find_events_by_aggregate_id(aggregate.aggregate_id)
          expect(stored_events.map(&:aggregate_table_id)).to all(eq(aggregate.id))
          expect(stored_events.size).to eq(events.size)
        end
      end
    end

  end
end
