require 'spec_helper'
require 'yaml'

module SandthornDriverSequel
	describe EventStore do
		before(:each) { prepare_for_test }
		let(:aggregate_id) { @id ||= UUIDTools::UUID.random_create.to_s }
		let(:test_events) { [{aggregate_version: 1, event_data: nil, event_name: "new"},{aggregate_version: 2, event_data: nil, event_name: "foo"}] } 
		let(:additional_events) { [{aggregate_version: 3, event_data: nil, event_name: "klopp"},{aggregate_version: 4, event_data: nil, event_name: "flipp"}] } 
		let(:snapshot_data) { { event_data: YAML.dump(Object.new), aggregate_version: 2 } }		
		let(:save_snapshot) { event_store.save_snapshot snapshot_data, aggregate_id }
		let(:save_events) { event_store.save_events test_events, aggregate_id, SandthornDriverSequel::EventStore }
		let(:save_additional_events) { event_store.save_events additional_events, aggregate_id, SandthornDriverSequel::EventStore }
		context "when loading an aggregate using get_aggregate" do
			context "and it has a snapshot" do
				before(:each) do
					save_events
					save_snapshot
					save_additional_events
				end
				let(:events) { event_store.get_aggregate aggregate_id, SandthornDriverSequel::EventStore }
				it "should have the first event as :aggregate_set_from_snapshot" do
					expect(events.first[:event_name]).to eql "aggregate_set_from_snapshot"
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
					expect(snap).to eql snapshot_data
				end
			end
			context "when trying to save a snapshot on a non-existing aggregate" do
				it "should raise a NonAggregateError" do
					expect { save_snapshot }.to raise_error SandthornDriverSequel::Errors::NoAggregateError
				end
			end
			context "when trying to save a snapshot with a non-existing aggregate_version" do
				before(:each) { save_events }
				it "should raise a WrongAggregateVersion error" do
					data = snapshot_data
					data[:aggregate_version] = 100
					expect { event_store.save_snapshot data, aggregate_id }.to raise_error SandthornDriverSequel::Errors::WrongSnapshotVersionError
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
					data = snapshot_data
					data[:aggregate_version] = 1
					event_store.save_snapshot(data, aggregate_id)
					snap = event_store.get_snapshot(aggregate_id)
					expect(snap).to eql data
				end
			end
		end
	end
end