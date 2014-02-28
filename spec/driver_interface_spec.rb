require 'spec_helper'

module SandthornDriverSequel
	describe EventStore do
		before(:each) { prepare_for_test }
		context "interface structure" do
			let(:subject) {event_store}
			it "should respond to save_events" do
				subject.should respond_to("save_events")
			end

			it "should respond to save_snapshot" do
				subject.should respond_to("save_snapshot")
			end

			it "should respond to get_aggregate" do
				subject.should respond_to("get_aggregate")
			end

			it "should respond to get_aggregate_events" do
				subject.should respond_to("get_aggregate_events")
			end

			it "should respond to get_aggregate_list_by_typename" do
				subject.should respond_to("get_aggregate_list_by_typename")
			end

			it "should respond to get_all_typenames" do
				subject.should respond_to("get_all_typenames")
			end

			it "should respond to get_snapshot" do
				subject.should respond_to("get_snapshot")
			end

			it "should respond to get_new_events_after_event_id_matching_classname" do
				subject.should respond_to("get_new_events_after_event_id_matching_classname")
			end

			it "should respond to get_events_after_sequence_id" do
				subject.should respond_to(:get_events)
			end
			it("should respond to url"){ expect(subject).to respond_to :url }
			it("should respond to context"){ expect(subject).to respond_to :context }
			it("should respond to driver"){ expect(subject).to respond_to :driver }
		end
	end
end