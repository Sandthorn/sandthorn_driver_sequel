require 'spec_helper'

module SandthornDriverSequel
  describe EventStore do
    before(:each) { prepare_for_test }
    context "interface structure" do
      let(:subject) { event_store }
      methods = [
        :save_events,
        :save_snapshot,
        :get_aggregate_events_from_snapshot,
        :get_snapshot,
        :get_events,
        :context,
        :driver,
        :all,
        :find
      ]

      methods.each do |method|
        it "responds to #{method}" do
          expect(subject).to respond_to(method)
        end
      end

    end
  end
end