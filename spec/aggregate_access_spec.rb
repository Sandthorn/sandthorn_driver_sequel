require 'spec_helper'

module SandthornDriverSequel
  describe AggregateAccess do
    include EventStoreContext
    let(:context) { :test }
    let(:db) { Sequel.connect(event_store_url)}
    let(:aggregate_id) { generate_uuid }
    let(:storage) { Storage.new(db, :test) }
    let(:access) { AggregateAccess.new(storage) }

    before { prepare_for_test }

    describe "#find" do
      it "finds by table id" do
        aggregate = access.register_aggregate(aggregate_id, "boo")
        aggregate = access.find(aggregate.id)
        expect(aggregate.aggregate_id).to eq(aggregate_id)
        expect(aggregate.aggregate_type).to eq("boo")
      end

      it "doesn't find by table id" do
        access.register_aggregate(aggregate_id, "foo")
        max_id = db[aggregates_table_name].max(:id)
        expect(access.find(max_id + 1)).to be_nil
      end
    end

    describe "#find_by_aggregate_id" do
      context "when the aggregate is registered" do
        it "returns the aggregate" do
          access.register_aggregate(aggregate_id, "bar")
          aggregate = access.find_by_aggregate_id(aggregate_id)
          expect(aggregate.aggregate_id).to eq(aggregate_id)
        end
      end

      context "when the aggregate isn't registered" do
        it "returns nil" do
          expect(access.find_by_aggregate_id(aggregate_id)).to be_nil
        end
      end
    end

    describe "#find_or_register" do
      context "when the aggregate is registered" do
        it "returns the aggregate" do
          access.register_aggregate(aggregate_id, "baz")
          aggregate = access.find_or_register(aggregate_id, "qux")
          expect(aggregate.aggregate_id).to eq(aggregate_id)
          expect(aggregate.aggregate_type).to eq("baz")
        end
      end
    end

    describe "#register_aggregate" do
      it "returns the aggregate" do
        aggregate = access.register_aggregate(aggregate_id, "bar")
        expect(aggregate.aggregate_id).to eq(aggregate_id)
        expect(aggregate.aggregate_type).to eq("bar")
        expect(aggregate.id).to_not be_nil
      end
    end

    describe "#aggregate_ids" do
      context "when given no argument" do
        it "returns all aggregate ids" do
          aggregate_ids = 3.times.map { generate_uuid }
          aggregate_ids.each { |id| access.register_aggregate(id, "foo") }
          expect(access.aggregate_ids).to eq(aggregate_ids)
        end
      end
      context "when given an aggregate type" do
        it "returns only aggregates of that type" do
          foo_agg_id, bar_agg_id = generate_uuid, generate_uuid
          access.register_aggregate(foo_agg_id, "foo")
          access.register_aggregate(bar_agg_id, "bar")
          expect(access.aggregate_ids(aggregate_type: "foo")).to eq([foo_agg_id])
        end        
      end
    end

    def generate_uuid
      SecureRandom.uuid
    end
  end
end
