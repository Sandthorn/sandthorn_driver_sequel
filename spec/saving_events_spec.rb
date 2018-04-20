require 'spec_helper'

module SandthornDriverSequel
  describe EventStore do
    before(:each) { prepare_for_test }
    context "when saving a prefectly sane event stream" do
      let(:test_events) do
        e = []
        e << {aggregate_version: 1, event_name: "new", event_data: {:attribute_name=>"aggregate_id", :old_value=>nil, :new_value=>"0a74e545-be84-4506-8b0a-73e947856327"}, event_metadata: [1,2,3]}
        e << {aggregate_version: 2, event_name: "foo", event_data: "noop", event_metadata: nil}
        e << {aggregate_version: 3, event_name: "flubber", event_data: "noop", event_metadata: nil}
      end

      let(:aggregate_id) { "c0456e26-e29a-4f67-92fa-130b3a31a39a" }

      it "should be able to save and retrieve events on the aggregate" do
        event_store.save_events test_events, aggregate_id, String
        events = event_store.find aggregate_id, String
        expect(events.length).to eql test_events.length
      end

      it "should have correct keys when asking for events" do
        event_store.save_events test_events, aggregate_id, String
        events = event_store.find aggregate_id, String
        event = events.first
        expect(event[:event_data]).to eql(test_events.first[:event_data])
        expect(event[:event_metadata]).to eql(test_events.first[:event_metadata])
        expect(event[:event_name]).to eql("new")
        expect(event[:aggregate_id]).to eql aggregate_id
        expect(event[:aggregate_version]).to eql 1
        expect(event[:sequence_number]).to be_a(Fixnum)
        expect(event[:timestamp]).to be_a(Time)
      end
    end

    context "when saving two aggregate types" do
      let(:test_events_1) do
        e = []
        e << {aggregate_version: 1, event_name: "new", event_data: {:attribute_name=>"aggregate_id", :old_value=>nil, :new_value=>"0a74e545-be84-4506-8b0a-73e947856327"}, event_metadata: nil}
        e << {aggregate_version: 2, event_name: "foo", event_data: "noop", event_metadata: nil}
        e << {aggregate_version: 3, event_name: "flubber", event_data: "noop", event_metadata: nil}
      end
      let(:test_events_2) do
        e = []
        e << {aggregate_version: 1, event_name: "new", event_data: {:attribute_name=>"aggregate_id", :old_value=>nil, :new_value=>"0a74e545-be84-4506-8b0a-73e947856327"}, event_metadata: nil}
      end
      let(:aggregate_id_1) {"c0456e26-e29a-4f67-92fa-130b3a31a39a"}
      let(:aggregate_id_2) {"c0456e26-e92b-4f67-92fa-130b3a31b93b"}
      let(:aggregate_id_3) {"c0456e26-e92b-1234-92fa-130b3a31b93b"}

      before(:each) do
        event_store.save_events test_events_1, aggregate_id_1, String
        event_store.save_events test_events_2, aggregate_id_2, Hash
        event_store.save_events test_events_2, aggregate_id_3, String
      end

      it "should get the correct aggregate_id in events when asking for all" do
        aggregate_events = event_store.all(String)
        expect(aggregate_events.length).to eql 2
        expect(aggregate_events.first.any? { |e| e[:aggregate_id] == aggregate_id_1 }).to be_truthy
        expect(aggregate_events.last.any? { |e| e[:aggregate_id] == aggregate_id_3 }).to be_truthy
      end
    end

    context "when saving events that have no aggregate_version" do
      let(:test_events) do
        e = []
        e << {aggregate_version: nil, event_name: "new", event_data: {:attribute_name=>"aggregate_id", :old_value=>nil, :new_value=>"0a74e545-be84-4506-8b0a-73e947856327"}, event_metadata: nil}
        e << {aggregate_version: nil, event_name: "foo", event_data: "noop", event_metadata: nil}
        e << {aggregate_version: nil, event_name: "flubber", event_data: "noop", event_metadata: nil}
      end

      let(:aggregate_id) { "c0456e26-e29a-4f67-92fa-130b3a31a39a" }

      it "should be able to save and retrieve events on the aggregate" do
        event_store.save_events test_events, aggregate_id, String
        events = event_store.find aggregate_id, String
        expect(events.length).to eql test_events.length
      end

      it "should have correct keys when asking for events" do
        event_store.save_events test_events, aggregate_id, String
        events = event_store.find aggregate_id, String
        event = events.first

        expect(event[:event_data]).to eql(test_events.first[:event_data])
        expect(event[:event_name]).to eql("new")
        expect(event[:aggregate_id]).to eql aggregate_id
        expect(event[:aggregate_version]).to eql 1
        expect(event[:sequence_number]).to be_a(Fixnum)
        expect(event[:timestamp]).to be_a(Time)
      end
    end

  end
end
