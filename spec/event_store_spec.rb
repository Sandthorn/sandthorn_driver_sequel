require 'spec_helper'
module SandthornDriverSequel
  describe EventStore do
    
    before(:each) { prepare_for_test context: nil; }
    let(:event_store) { SandthornDriverSequel.driver_from_url url: event_store_url }  
    
    describe("when getting the same data from find and get_aggregate_events_from_snapshot") do
      let(:test_events) do
        e = [] 
        e << {aggregate_version: 1, event_name: "new",  event_data: {:method_name=>"new", :method_args=>[], :attribute_deltas=>[{:attribute_name=>"aggregate_id", :old_value=>nil, :new_value=>aggregate_id}]}}
        e << {aggregate_version: 2, event_name: "foo",  event_data: "noop"}
        e << {aggregate_version: 3, event_name: "flubber",  event_data: "noop"}
      end
      let(:aggregate_id) {"c0456e26-e29a-4f67-92fa-130b3a31a39b"}
      
      

      before do
        event_store.save_events test_events, aggregate_id, String
      end

      context "find" do

        let(:find_events) do
          event_store.find aggregate_id, "String"
        end

        let(:get_aggregate_events_from_snapshot_events) do
          event_store.get_aggregate_events_from_snapshot aggregate_id
        end

        it "should get same events" do
          find_events.each_with_index do |event, index|
            expect(find_events[index]).to eql get_aggregate_events_from_snapshot_events[index]
          end
        end
      end

      context "all" do

        let(:test_events_2) do
          e = [] 
          e << {aggregate_version: 1, event_name: "new",  event_data: {:method_name=>"new", :method_args=>[], :attribute_deltas=>[{:attribute_name=>"aggregate_id", :old_value=>nil, :new_value=>aggregate_id_2}]}}
          e << {aggregate_version: 2, event_name: "foo",  event_data: "noop"}
          e << {aggregate_version: 3, event_name: "flubber",  event_data: "noop"}
        end
        let(:aggregate_id_2) {"d0456e26-e29a-4f67-92fa-130b3a31a39b"}

        before do
          event_store.save_events test_events_2, aggregate_id_2, String
        end

        let(:all_events) do
          event_store.all String
        end

        let(:obsolete_all) do
          return event_store.get_aggregate_ids(aggregate_type: String).map do |id|
            event_store.get_aggregate_events_from_snapshot(id)
          end
        end

        it "should get two arrays of events" do
          expect(all_events.length).to eql 2
        end

        it "should get same events" do
          all_events.each_with_index do |events, index|
            expect(events).to eql obsolete_all[index]
          end
        end
      end
    end
  end
end