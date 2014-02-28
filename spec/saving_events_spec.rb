require 'spec_helper'

module SandthornDriverSequel
	describe EventStore do
		before(:each) { prepare_for_test }
		context "when saving a prefectly sane event stream" do
			let(:test_events) do
				e = [] 
				e << {aggregate_version: 1, event_name: "new", event_args: nil, event_data: "---\n:method_name: new\n:method_args: []\n:attribute_deltas:\n- :attribute_name: :@aggregate_id\n  :old_value: \n  :new_value: 0a74e545-be84-4506-8b0a-73e947856327\n"}
				e << {aggregate_version: 2, event_name: "foo", event_args: ["bar"], event_data: "noop"}
				e << {aggregate_version: 3, event_name: "flubber", event_args: ["bar"] , event_data: "noop"}
			end
			let(:aggregate_id) {"c0456e26-e29a-4f67-92fa-130b3a31a39a"}
			it "should be able to save and retreive events on the aggregate" do
				event_store.save_events test_events, 0, aggregate_id, String
				events = event_store.get_aggregate_events aggregate_id, String
				events.length.should eql test_events.length
			end
			it "should fail if aggregate does not exist and version is above 0" do
				expect { event_store.save_events test_events, 1, aggregate_id, String }.to raise_error SandthornDriverSequel::Errors::NoAggregateError
			end
			it "should fail if originating version is wrong" do
				event_store.save_events test_events, 0, aggregate_id, String
				expect { event_store.save_events test_events, 102, aggregate_id, String }.to raise_error SandthornDriverSequel::Errors::WrongAggregateVersionError
			end
			it "should have correct keys when asking for events" do
				event_store.save_events test_events, 0, aggregate_id, String
				events = event_store.get_aggregate aggregate_id, String
				event = events.first
				event[:event_data].should eql(test_events.first[:event_data])
      			event[:event_name].should eql("new")
      			event[:aggregate_id].should eql aggregate_id
      			event[:aggregate_version].should eql 1
      			event[:sequence_number].should be_a(Fixnum)
      			event[:timestamp].should be_a(Time)
			end
		end
		context "when saving two aggregate types" do
			let(:test_events_1) do
				e = [] 
				e << {aggregate_version: 1, event_name: "new", event_args: nil, event_data: "---\n:method_name: new\n:method_args: []\n:attribute_deltas:\n- :attribute_name: :@aggregate_id\n  :old_value: \n  :new_value: 0a74e545-be84-4506-8b0a-73e947856327\n"}
				e << {aggregate_version: 2, event_name: "foo", event_args: ["bar", event_data: "noop"]}
				e << {aggregate_version: 3, event_name: "flubber", event_args: ["bar", event_data: "noop"]}
			end	
			let(:test_events_2) do
				e = [] 
				e << {aggregate_version: 1, event_name: "new", event_args: nil, event_data: "---\n:method_name: new\n:method_args: []\n:attribute_deltas:\n- :attribute_name: :@aggregate_id\n  :old_value: \n  :new_value: 0a74e545-be84-4506-8b0a-73e947856327\n"}
			end	
			let(:aggregate_id_1) {"c0456e26-e29a-4f67-92fa-130b3a31a39a"}
			let(:aggregate_id_2) {"c0456e26-e92b-4f67-92fa-130b3a31b93b"}
			let(:aggregate_id_3) {"c0456e26-e92b-1234-92fa-130b3a31b93b"}
			before(:each) do
				event_store.save_events test_events_1, 0, aggregate_id_1, String
				event_store.save_events test_events_2, 0, aggregate_id_2, Hash
				event_store.save_events test_events_2, 0, aggregate_id_3, String
			end
			it "both types should exist in get_all_typenames in alphabetical order" do
				names = event_store.get_all_typenames
				names.length.should eql 2
				names.first.should eql "Hash"
				names.last.should eql "String"
			end
			it "should list the aggregate ids when asking for get_aggregate_list_by_typename" do
				ids = event_store.get_aggregate_list_by_typename String
				ids.length.should eql 2
				ids.any? { |e| e == aggregate_id_1 }.should be_true
				ids.any? { |e| e == aggregate_id_3 }.should be_true
			end
		end
	end
end