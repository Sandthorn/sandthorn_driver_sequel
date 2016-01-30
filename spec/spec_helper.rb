require 'sandthorn_driver_sequel'
require 'sandthorn_driver_sequel/migration'
require 'ap'
require 'uuidtools'

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.filter_run_excluding benchmark: true
  config.order = 'random'
end
def prepare_for_test context: :test
  migrator = SandthornDriverSequel::Migration.new url: event_store_url, context: context
  migrator.migrate!
  migrator.send(:clear_for_test)
end

def event_store_url
  "sqlite://spec/db/event_store.sqlite3"
  #"postgres://morganhallgren@localhost:5432/test_1"
end

def event_store context: :test
  SandthornDriverSequel.driver_from_url url: event_store_url, context: context

  #SandthornDriverSequel::EventStore.new url: event_store_url, context: context
end
