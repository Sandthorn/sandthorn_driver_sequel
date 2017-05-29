# require 'spec_helper'
# module SandthornDriverSequel
#   describe EventStore do
    
#     before(:each) { prepare_for_test context: nil; }
#     let(:event_store) { SandthornDriverSequel.driver_from_url url: event_store_url }  
    
#     describe("when getting the same data from find and aggregate_events") do
#       let(:test_events) do
#         e = [] 
#         e << {aggregate_version: 1, event_name: "new",  event_data: {:attribute_deltas=>[{:attribute_name=>"aggregate_id", :old_value=>nil, :new_value=>aggregate_id}]}, event_meta_data: nil}
#         e << {aggregate_version: 2, event_name: "foo",  event_data: "noop", event_meta_data: nil}
#         e << {aggregate_version: 3, event_name: "flubber",  event_data: "noop", event_meta_data: nil}
#       end
#       let(:aggregate_id) {"c0456e26-e29a-4f67-92fa-130b3a31a39b"}
      
#       before do
#         event_store.save_events test_events, aggregate_id, String
#       end

#       context "all" do

#         let(:test_events_2) do
#           e = [] 
#           e << {aggregate_version: 1, event_name: "new",  event_data: {:attribute_deltas=>[{:attribute_name=>"aggregate_id", :old_value=>nil, :new_value=>aggregate_id_2}]}, event_meta_data: nil}
#           e << {aggregate_version: 2, event_name: "foo",  event_data: "noop", event_meta_data: nil}
#           e << {aggregate_version: 3, event_name: "flubber",  event_data: "noop", event_meta_data: nil}
#         end
#         let(:aggregate_id_2) {"d0456e26-e29a-4f67-92fa-130b3a31a39b"}

#         before do
#           event_store.save_events test_events_2, aggregate_id_2, String
#         end

#         let(:all_events) do
#           event_store.all String
#         end

#         it "should get two arrays of events" do
#           expect(all_events.length).to eql 2
#         end

#       end
#     end
#   end
# end