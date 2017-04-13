require 'spec_helper'
module SandthornDriverSequel
  describe EventStore do
    let(:context) { :event_store_spec }
    before(:each) { prepare_for_test context: context; prepare_for_test context: nil; }
    let(:event_store_with_context) { SandthornDriverSequel.driver_from_url url: event_store_url, context: context  }  
    let(:event_store_without_context) { SandthornDriverSequel.driver_from_url url: event_store_url }
    context("when saving in one context and retrieving in another") do
      let(:test_events) do
        e = [] 
        e << {aggregate_version: 1, event_name: "new",  event_data: {:attribute_deltas=>[{:attribute_name=>"aggregate_id", :old_value=>nil, :new_value=>"0a74e545-be84-4506-8b0a-73e947856327"}]}}
        e << {aggregate_version: 2, event_name: "foo",  event_data: "noop"}
        e << {aggregate_version: 3, event_name: "flubber",  event_data: "noop"}
      end
      let(:aggregate_id) {"c0456e26-e29a-4f67-92fa-130b3a31a39b"}
      it "should not find them" do
        event_store_without_context.save_events test_events, aggregate_id, String
        events = event_store_without_context.get_aggregate_events aggregate_id
        expect(events.length).to eql test_events.length
        events_2 = event_store_with_context.get_aggregate_events aggregate_id
        expect(events_2.length).to eql 0
      end
    end
  end
end