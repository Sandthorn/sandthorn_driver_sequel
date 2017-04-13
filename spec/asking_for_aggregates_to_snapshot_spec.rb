require 'spec_helper'

class Foo; end
class Bar; end

module SandthornDriverSequel

  describe EventStore do
    before(:each) { prepare_for_test }
    let(:aggregate) { Struct::AggregateMock.new(aggregate_id, 11) }
    let(:aggregate_id) { @id ||= UUIDTools::UUID.random_create.to_s }
    context "when asking for aggregates to snapshot" do
      let(:aggregates) {
        [{id: "1", class_name: Foo}, {id: aggregate_id, class_name: Struct::AggregateMock},{id: "3", class_name: Foo}]}

      before(:each) {save_test_events}

      context "when asking for type 'Bar' and max event count 5" do
        let(:needs_snapshot) { event_store.obsolete_snapshots aggregate_types: [Struct::AggregateMock], max_event_distance: 5 }
        context "and no snapshots exist" do
          it "should return that id 2 with class Struct::AggregateMock need to be snapshotted" do
            expect(needs_snapshot.length).to eql 1
            expect(needs_snapshot.first[:aggregate_id]).to eql aggregates[1][:id]
            expect(needs_snapshot.first[:aggregate_type]).to eql "Struct::AggregateMock"
          end
        end
        context "and a recent snapshot exists" do
          before(:each) do
            snapshot_data = { event_data: "YO MAN", aggregate_version: 11 }
            event_store.save_snapshot(aggregate)
          end
          it "should return nil" do
            expect(needs_snapshot).to be_empty
          end
        end
      end


      def save_test_events
        for_1 = event_generator count: 4, start_at: 1
        for_2 = event_generator count: 3, start_at: 1
        for_3 = event_generator count: 6, start_at: 1
        for_2_2 = event_generator count: 10, start_at: 4
        for_1_2 = event_generator count: 1, start_at: 5
        save_events for_1, 0
        save_events for_2, 1
        save_events for_3, 2
        save_events for_1_2, 0
        save_events for_2_2, 1
      end
      def save_events events, aggregate_index
        event_store.save_events events, aggregates[aggregate_index][:id], aggregates[aggregate_index][:class_name]
      end

      def event_generator count: 1, start_at: 1
        events = []
        i = 0
        while i < count do
          events << { aggregate_version: i+start_at, event_data: nil, event_name: "event_foo_#{i}" , event_meta_data: nil}
          i += 1
        end
        events
      end
    end
  end
end