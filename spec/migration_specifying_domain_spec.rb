require 'spec_helper'

module SandthornDriverSequel
  describe Migration do
    def check_tables context = nil
      events = :events
      aggregates = :aggregates
      
      if context
        events = "#{context}_#{events}".to_sym
        aggregates = "#{context}_#{aggregates}".to_sym
      
      end
      migration.driver.execute do |db|
        expect(db.table_exists? events).to be_truthy, "expected table :#{events} to exist, but it didn't"
        expect(db.table_exists? aggregates).to be_truthy, "expected table :#{aggregates} to exist, but it didn't"
      
      end
    end
    let(:migration) { Migration.new url: event_store_url, context: context  }
    before(:each) { migration.migrate! }
    context "when default (nil) eventstore contex" do
      let(:context) { nil }
      it "should create the tables events and aggregates" do
        check_tables
      end
    end
    context "when specifying context" do
      let(:context) { :another_domain }
      it "should create the tables events and aggregates" do
        check_tables context
      end
    end

    context "when migrating a connection" do
      let(:migration) { Migration.new connection: Sequel.sqlite, context: context }
      let(:context) { :some_domain }
      it "should create the tables events and aggregates" do
        check_tables context
      end
    end
  end
end
