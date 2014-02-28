require 'spec_helper'

module SandthornDriverSequel
	describe Migration do
		def check_tables context = nil
			events = :events
			aggregates = :aggregates
			snapshots = :snapshots
			if context
				events = "#{context}_#{events}".to_sym 
				aggregates = "#{context}_#{aggregates}".to_sym 
				snapshots = "#{context}_#{snapshots}".to_sym 
			end
			migration.driver.execute do |db|
				expect(db.table_exists? events).to be_true, "expected table :#{events} to exist, but it didn't"
				expect(db.table_exists? aggregates).to be_true, "expected table :#{aggregates} to exist, but it didn't"
				expect(db.table_exists? snapshots).to be_true, "expected table :#{snapshots} to exist, but it didn't"
			end	
		end
		let(:migration) { Migration.new url: event_store_url, context: context  }
		before(:each) { migration.migrate! }
		context "when default (nil) eventstore contex" do 
			let(:context) { nil }
			it "should create the tables events, aggregates and snapshots" do
				check_tables
			end
		end
		context "when specifying context" do 
			let(:context) { :another_domain }
			it "should create the tables events, aggregates and snapshots" do
				check_tables context
			end
		end
	end
end