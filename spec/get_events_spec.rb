require 'spec_helper'

module SandthornDriverSequel
	describe EventStore do
		before(:each) { prepare_for_test }
		let(:test_events_a) do
			e = [] 
			e << {aggregate_version: 1, event_name: "new", event_data: "---\n:method_name: new\n:method_args: []\n:attribute_deltas:\n- :attribute_name: :@aggregate_id\n  :old_value: \n  :new_value: 0a74e545-be84-4506-8b0a-73e947856327\n"}
			e << {aggregate_version: 2, event_name: "foo", event_data: "A2"}
			e << {aggregate_version: 3, event_name: "bard", event_data: "A3"}
		end
		let(:aggregate_id_a) {"c0456e26-e29a-4f67-92fa-130b3a31a39a"}
		let(:test_events_b) do
			e = [] 
			e << {aggregate_version: 1, event_name: "new", event_data: "B1" }
			e << {aggregate_version: 2, event_name: "foo", event_data: "B2"}
			e << {aggregate_version: 3, event_name: "bar", event_data: "B3"}
		end
		let(:aggregate_id_b) {"c0456e26-1234-4f67-92fa-130b3a31a39a"}
		let(:test_events_c) do
			e = [] 
			e << {aggregate_version: 1, event_name: "new", event_data: "C1" }
		end
		let(:test_events_c_2) do
			e = [] 
			e << {aggregate_version: 2, event_name: "flubber", event_data: "C2" }
		end
		let(:aggregate_id_c) {"c0456e26-2345-4f67-92fa-130b3a31a39a"}
		before(:each) do
			event_store.save_events test_events_a, 0, aggregate_id_a, SandthornDriverSequel::EventStore
			event_store.save_events test_events_c, 0, aggregate_id_c, String
			event_store.save_events test_events_b, 0, aggregate_id_b, SandthornDriverSequel::SequelDriver
			event_store.save_events test_events_c_2, 1, aggregate_id_c, String
		end
		context "when using get_events" do 
			context "and using take" do
				let(:events) {event_store.get_events after_sequence_number: 0, include_events: [:new], take: 2}
				it "should find 2 events" do
					events.length.should eql 2
				end
			end
			context "and getting events of type :new" do
				let(:events) {event_store.get_events after_sequence_number: 0, include_events: [:new]}
				it "should find 3 events" do
					events.length.should eql 3
				end
				it "should only be new-events" do
					events.all? { |e| e[:event_name] == "new"  }
				end
			end
			context "and combining args" do
				let(:events) do
					all = event_store.get_events after_sequence_number: 0
					first_seq_number = all[0][:sequence_number]				
					event_store.get_events after_sequence_number: first_seq_number , exclude_events: [:foo],  include_events: [:new, :foo, "bar", :flubber], take: 100 
				end
				it "should find 4 events" do
					events.length.should eql 4
				end
				it "should not be any foo-events" do
					events.all? { |e| e[:event_name] != "foo" }
				end
			end
			context "and getting all events but excluding new" do
				let(:events) {event_store.get_events after_sequence_number: 0, exclude_events: [:new] }
				it "should find 5 events" do
					events.length.should eql 5
				end
				it "should only be new and foo-events" do
					events.all? { |e| e[:event_name] != "new" }
				end
			end
			context "and getting events of type :new and foo" do
				let(:events) {event_store.get_events after_sequence_number: 0, aggregate_types: ["String", SandthornDriverSequel::EventStore], include_events: [:new, "foo"]}
				it "should find 3 events" do
					events.length.should eql 3
				end
				it "should only be new and foo-events" do
					events.all? { |e| e[:event_name] == "new" || e[:event_name] == "foo" }
				end
			end
			context "and getting events for SandthornDriverSequel::EventStore, and String after 0" do
				let(:events) {event_store.get_events after_sequence_number: 0, aggregate_types: [SandthornDriverSequel::EventStore, String]}
				it "should find 5 events" do
					events.length.should eql 5
				end
				it "should be in sequence_number order" do
					check = 0
					events.each { |e| e[:sequence_number].should be > check; check = e[:sequence_number] }
				end
				it "should contain only events for aggregate_id_a and aggregate_id_c" do
					events.each { |e| [aggregate_id_a, aggregate_id_c].include?(e[:aggregate_id]).should be_true }
				end
			end
			context "and getting events for SandthornDriverSequel::EventStore after 0" do
				let(:events) {event_store.get_events after_sequence_number: 0, aggregate_types: [SandthornDriverSequel::EventStore]}
				it "should find 3 events" do
					events.length.should eql 3
				end
				it "should be in sequence_number order" do
					check = 0
					events.each { |e| e[:sequence_number].should be > check; check = e[:sequence_number] }
				end
				it "should contain only events for aggregate_id_a" do
					events.each { |e| e[:aggregate_id].should eql aggregate_id_a  }
				end
			end
		end
		context "when using :get_new_events_after_event_id_matching_classname to get events" do
			context "and getting events for SandthornDriverSequel::EventStore after 0" do
				let(:events) {event_store.get_new_events_after_event_id_matching_classname 0, SandthornDriverSequel::EventStore}
				it "should find 3 events" do
					events.length.should eql 3
				end
				it "should be in sequence_number order" do
					check = 0
					events.each { |e| e[:sequence_number].should be > check; check = e[:sequence_number] }
				end
				it "should contain only events for aggregate_id_a" do
					events.each { |e| e[:aggregate_id].should eql aggregate_id_a  }
				end
				it "should be able to get events after a sequence number" do
					new_from = events[1][:sequence_number]
					ev = event_store.get_new_events_after_event_id_matching_classname new_from, SandthornDriverSequel::EventStore
					ev.last[:aggregate_version].should eql 3
					ev.length.should eql 1
				end
				it "should be able to limit the number of results" do
					ev = event_store.get_new_events_after_event_id_matching_classname 0, SandthornDriverSequel::EventStore, take: 2
					ev.length.should eql 2
					ev.last[:aggregate_version].should eql 2
				end
			end
			context "and getting events for String after 0" do
				let(:events) {event_store.get_new_events_after_event_id_matching_classname 0, "String"}
				it "should find 3 events" do
					events.length.should eql 2
				end
				it "should be in sequence_number order" do
					check = 0
					events.each { |e| e[:sequence_number].should be > check; check = e[:sequence_number] }
				end
				it "should contain only events for aggregate_id_c" do
					events.each { |e| e[:aggregate_id].should eql aggregate_id_c  }
				end
			end
		end

	end
end