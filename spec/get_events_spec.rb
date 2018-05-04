require 'spec_helper'

module SandthornDriverSequel
  describe EventStore do
    before(:each) { prepare_for_test }
    let(:test_events_a) do
      e = []
      e << {aggregate_version: 1, aggregate_id: "0a74e545-be84-4506-8b0a-73e947856327", event_name: "new", event_data: {}, event_metadata: {a: 1}}
      e << {aggregate_version: 2, aggregate_id: "0a74e545-be84-4506-8b0a-73e947856327", event_name: "foo", event_data: "A2", event_metadata: {a: 1}}
      e << {aggregate_version: 3, aggregate_id: "0a74e545-be84-4506-8b0a-73e947856327", event_name: "bard", event_data: "A3", event_metadata: {a: 1}}
    end
    let(:aggregate_id_a) {"c0456e26-e29a-4f67-92fa-130b3a31a39a"}
    let(:test_events_b) do
      e = []
      e << {aggregate_version: 1, aggregate_id: "c0456e26-e29a-4f67-92fa-130b3a31a39a", event_name: "new", event_data: "B1", event_metadata: 1}
      e << {aggregate_version: 2, aggregate_id: "c0456e26-e29a-4f67-92fa-130b3a31a39a", event_name: "foo", event_data: "B2", event_metadata: 2}
      e << {aggregate_version: 3, aggregate_id: "c0456e26-e29a-4f67-92fa-130b3a31a39a", event_name: "bar", event_data: "B3", event_metadata: 3}
    end
    let(:aggregate_id_b) {"c0456e26-1234-4f67-92fa-130b3a31a39a"}
    let(:test_events_c) do
      e = []
      e << {aggregate_version: 1, aggregate_id: "c0456e26-e29a-4f67-92fa-130b3a31a39a", event_name: "new", event_data: "C1", event_metadata: 4}
    end
    let(:test_events_c_2) do
      e = []
      e << {aggregate_version: 2, aggregate_id: "c0456e26-e29a-4f67-92fa-130b3a31a39a", event_name: "flubber", event_data: "C2", event_metadata: 6}
    end
    let(:aggregate_id_c) {"c0456e26-2345-4f67-92fa-130b3a31a39a"}
    before(:each) do
      event_store.save_events test_events_a, aggregate_id_a, SandthornDriverSequel::EventStore
      event_store.save_events test_events_c, aggregate_id_c, String
      event_store.save_events test_events_b, aggregate_id_b, SandthornDriverSequel::SequelDriver
      event_store.save_events test_events_c_2, aggregate_id_c, String
    end

    let(:event) { event_store.get_events(take: 1).first }

    it "returns events that can be merged" do
      expect(event).to respond_to(:merge)
    end

    context "when using get_events" do
      context "and using take" do
        let(:events) {event_store.get_events after_sequence_number: 0, take: 2}
        it "should find 2 events" do
          expect(events.length).to eql 2
        end
      end
      context "and combining args" do
        let(:events) do
          all = event_store.get_events after_sequence_number: 0
          first_seq_number = all[0][:sequence_number]
          event_store.get_events after_sequence_number: first_seq_number, take: 100
        end
        it "should find 7 events" do
          expect(events.length).to eql 7
        end
        
      end
      context "and getting events for SandthornDriverSequel::EventStore, and String after 0" do
        let(:events) {event_store.get_events after_sequence_number: 0, aggregate_types: [SandthornDriverSequel::EventStore, String]}
        it "should find 5 events" do
          expect(events.length).to eql 5
        end
        it "should be in sequence_number order" do
          check = 0
          events.each { |e| expect(e[:sequence_number]).to be > check; check = e[:sequence_number] }
        end
        it "should contain only events for aggregate_id_a and aggregate_id_c" do
          events.each { |e| expect([aggregate_id_a, aggregate_id_c].include?(e[:aggregate_id])).to be_truthy }
        end
      end
      context "and getting events for SandthornDriverSequel::EventStore after 0" do
        let(:events) {event_store.get_events after_sequence_number: 0, aggregate_types: [SandthornDriverSequel::EventStore]}
        it "should find 3 events" do
          expect(events.length).to eql 3
        end
        it "should be in sequence_number order" do
          check = 0
          events.each { |e| expect(e[:sequence_number]).to be > check; check = e[:sequence_number] }
        end
        it "should contain only events for aggregate_id_a" do
          events.each { |e| expect(e[:aggregate_id]).to eql aggregate_id_a  }
        end

        it "shoul have correct event_metadata" do
          events.each { |e| expect(e[:event_metadata]).to eql ({a: 1})  }
        end
      end
    end
  
  end
end
