# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sandthorn_driver_sequel/version'

Gem::Specification.new do |spec|
  spec.name          = "sandthorn_driver_sequel"
  spec.version       = SandthornDriverSequel::VERSION
  spec.authors       = ["Lars Krantz", "Morgan Hallgren", "Jesper Josefsson"]
  spec.email         = ["lars.krantz@alaz.se", "morgan.hallgren@gmail.com", "jesper.josefsson@gmail.com"]
  spec.description   = %q{Sequel driver for Sandthorn}
  spec.summary       = %q{Sequel driver for Sandthorn}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "gem-release"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-doc"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "autotest-standalone"
  spec.add_development_dependency "uuidtools"
  spec.add_development_dependency "ruby-beautify"
  spec.add_development_dependency "msgpack"
  spec.add_development_dependency "snappy"
  spec.add_development_dependency "guard-rspec"

  spec.add_runtime_dependency     "sequel", "~> 4.17"
  spec.add_runtime_dependency     "pg"
end
