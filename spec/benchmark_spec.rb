require 'spec_helper'
require 'benchmark'
require 'yaml'

module Sandthorn
  module AggregateRoot

    describe "benchmark", benchmark: true do

      before(:each) { prepare_for_test }
      let(:test_events_20_events) do
        e = [] 
        e << {aggregate_version: 1, event_name: "new", event_data: {:attribute_deltas=>[{:attribute_name=>"aggregate_id", :old_value=>nil, :new_value=>"0a74e545-be84-4506-8b0a-73e947856327"}]}}
        19.times do |i| 
           e << {aggregate_version: i+2, event_name: "foo", event_data: "A2"}
        end
        e
      end
      let(:test_events_one_event) do
        e = [] 
        e << {aggregate_version: 1, event_name: "new", event_data: "B1" }
      end
      let(:test_events_two_events) do
        e = [] 
        e << {aggregate_version: 1, event_name: "new", event_data: {:attribute_deltas=>[{:attribute_name=>"aggregate_id", :old_value=>nil, :new_value=>"0a74e545-be84-4506-8b0a-73e947856327"}]}}
        e << {aggregate_version: 2, event_name: "foo", event_data: "A2"}
      end
      let(:aggregate_id) {"c0456e26-2345-4f67-92fa-130b3a31a39a"}
      let(:es) { event_store }

      
      n = 500
      describe "save" do
        it "one event save 500 times" do
          Benchmark.bm do |x|
            x.report("new change save find") { for i in 1..n; es.save_events(test_events_one_event, 0, i.to_s, SandthornDriverSequel::EventStore); end }
          end
        end
        it "two events save 500 times" do
          Benchmark.bm do |x|
            x.report("new change save find") { for i in 1..n; es.save_events(test_events_two_events, 0, i.to_s, SandthornDriverSequel::EventStore); end }
          end
        end
        it "twenty events save 500 times" do
          Benchmark.bm do |x|
            x.report("new change save find") { for i in 1..n; es.save_events(test_events_20_events, 0, i.to_s, SandthornDriverSequel::EventStore); end }
          end
        end
      end

      describe "find" do
        it "should find one event 500 times" do
          es.save_events(test_events_one_event, 0, aggregate_id, SandthornDriverSequel::EventStore)

          Benchmark.bm do |x|
            x.report("find") { for i in 1..n; es.get_aggregate(aggregate_id, SandthornDriverSequel::EventStore);  end }
          end
        end
        it "should find two events 500 times" do
          es.save_events(test_events_two_events, 0, aggregate_id, SandthornDriverSequel::EventStore)

          Benchmark.bm do |x|
            x.report("find") { for i in 1..n; es.get_aggregate(aggregate_id, SandthornDriverSequel::EventStore);  end }
          end
        end
        it "should find twenty events 500 times" do
          es.save_events(test_events_20_events, 0, aggregate_id, SandthornDriverSequel::EventStore)

          Benchmark.bm do |x|
            x.report("find") { for i in 1..n; es.get_aggregate(aggregate_id, SandthornDriverSequel::EventStore);  end }
          end
        end

      end
       
      # it "new save and find 500 aggregates" do

      #   Benchmark.bm do |x|
      #     x.report("new change save find") { for i in 1..n; es.save_events(test_events_a, 0, i.to_s, SandthornDriverSequel::EventStore); es.get_aggregate(i.to_s, SandthornDriverSequel::EventStore);  end }
      #   end

      # end
      
      # it "should commit 500 actions" do
      #   Benchmark.bm do |x|
      #     x.report("commit") { for i in 1..n; test_object.change_name "#{i}";  end }
      #   end
      # end
      # it "should commit and save 500 actions" do
      #   Benchmark.bm do |x|
      #     x.report("commit save") { for i in 1..n; test_object.change_name("#{i}").save;  end }
      #   end
      # end
    end
  end
end