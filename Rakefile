require "bundler/gem_tasks"

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)
task default: :spec

task :benchmark do
	sh "ulimit -n 8192 && rspec --tag benchmark"
end
