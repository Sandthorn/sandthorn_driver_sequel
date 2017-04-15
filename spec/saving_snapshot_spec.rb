require 'spec_helper'
require 'yaml'

module SandthornDriverSequel
  describe EventStore do
    before(:each) { prepare_for_test }
    let(:aggregate_id) { @id ||= UUIDTools::UUID.random_create.to_s }
    let(:test_events) { [{aggregate_version: 1, event_data: nil, event_name: "new", event_meta_data: nil},{aggregate_version: 2, event_data: nil, event_name: "foo", event_meta_data: nil}] } 
    let(:additional_events) { [{aggregate_version: 3, event_data: nil, event_name: "klopp", event_meta_data: nil},{aggregate_version: 4, event_data: nil, event_name: "flipp", event_meta_data: nil}] } 
    let(:aggregate) { Struct::AggregateMock.new aggregate_id, 2 }
    let(:save_snapshot) { event_store.save_snapshot aggregate }
    let(:save_events) { event_store.save_events test_events, aggregate_id, Struct::AggregateMock }
    let(:save_additional_events) { event_store.save_events additional_events, aggregate_id, Struct::AggregateMock }
    context "when loading an aggregate using find" do
      context "and it has a snapshot" do
        before(:each) do
          save_events
          save_snapshot
          save_additional_events
        end
        let(:events) { event_store.find aggregate_id, Struct::AggregateMock }
        it "should have the first event as :aggregate_set_from_snapshot" do
          expect(events.first[:aggregate]).to eql aggregate
        end
        it "should have additional events after first snapshot-event" do
          expect(events.length).to eql 1+additional_events.length
          expect(events[1][:aggregate_version]).to eql additional_events[0][:aggregate_version]
          expect(events.last[:aggregate_version]).to eql additional_events.last[:aggregate_version]
        end
      end

    end
    context "when saving a snapshot" do

      context "and events are saved beforehand" do
        before(:each) { save_events }
        it "should be able to save snapshot" do
          expect { save_snapshot }.to_not raise_error
        end
        it "should be able to save and get snapshot" do
          save_snapshot
          snap = event_store.get_snapshot(aggregate_id)
          expect(snap).to eql aggregate
        end
      end
      context "when trying to save a snapshot on a non-existing aggregate" do
        it "should raise a NonAggregateError" do
          expect { save_snapshot }.to raise_error SandthornDriverSequel::Errors::NoAggregateError
        end
      end

      context "when saving a snapshot twice" do
        before(:each) { save_events; save_snapshot }
        it "should not raise error" do
          expect { save_snapshot }.to_not raise_error
        end
      end
      context "when saving a snapshot on a version less than current version" do
        before(:each) { save_events; }
        it "should save without protesting" do
          data = Struct::AggregateMock.new aggregate_id, 1
          event_store.save_snapshot(data)
          snap = event_store.get_snapshot(aggregate_id)
          expect(snap).to eql data
        end
      end
    end
  end
end