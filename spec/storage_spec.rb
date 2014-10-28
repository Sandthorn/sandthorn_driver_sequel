require 'spec_helper'

module SandthornDriverSequel

  describe Storage do
    let(:context) { :test }
    before do
      prepare_for_test(context: context)
    end
    let(:db) { Sequel.connect(event_store_url) }
    let(:driver) { SequelDriver.new(event_store_url)}
    let(:storage) { Storage.new(db, context) }

    describe "#aggregates" do
      it "returns access to the aggregates dataset" do
        expect(storage.aggregates).to respond_to(:update)
      end
    end

    describe "anonymous aggegrate class" do
      it "can insert and read data" do
        create_aggregate
        aggregate = storage.aggregates.first(aggregate_id: "foo", aggregate_type: "Foo")
        expect(aggregate).to_not be_nil
      end

      it "can update data" do
        create_aggregate
        storage.aggregates.where(aggregate_id: "foo").update(aggregate_version: 2)
        aggregate = storage.aggregates.first(aggregate_id: "foo")
        expect(aggregate.aggregate_version).to eq(1)
      end
    end

    describe "#events" do
      it "returns access to the events dataset" do
        expect(storage.events).to respond_to(:update)
      end
    end

    describe "anonymous event class" do
      it "can insert and read data" do
        data, event_id = create_event
        event = storage.events.first(sequence_number: event_id).values
        expect(event).to eq(data.merge(sequence_number: event_id))
      end

      it "can update data" do
        data, event_id = create_event
        storage.events.where(sequence_number: event_id).update(event_name: "qux")
        event = storage.events.first(sequence_number: event_id)
        expect(event.event_name).to eq("qux")
      end
    end

    def create_aggregate
      storage.aggregates.insert(aggregate_id: "foo", aggregate_type: "Foo")
    end

    def create_event
      aggregate_table_id = create_aggregate
      data = {
          aggregate_table_id: aggregate_table_id,
          aggregate_version: 1,
          event_name: "foo",
          event_data: "bar",
          timestamp: Time.now
      }
      event_id = storage.events.insert(data)
      return data, event_id
    end

  end
end
