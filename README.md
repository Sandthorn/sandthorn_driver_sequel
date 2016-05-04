[![Code Climate](https://codeclimate.com/github/Sandthorn/sandthorn_driver_sequel.png)](https://codeclimate.com/github/Sandthorn/sandthorn_driver_sequel)

# Sandthorn Sequel-driver

A SQL database driver for [Sandthorn](https://github.com/Sandthorn/sandthorn), made with [Sequel](http://sequel.jeremyevans.net/).

## Installation

Add this line to your application's Gemfile:

    gem 'sandthorn_driver_sequel'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sandthorn_driver_sequel

## Usage

### `SandthornDriverSequel.configure`

Change the global configuration, the default data serialization for events and snapshots are YAML.

Change the serialization of events and snapshots to Oj.

```ruby
SandthornDriverSequel.configure { |conf|
  conf.event_serializer = Proc.new { |data| Oj::dump(data) }
  conf.event_deserializer = Proc.new { |data| Oj::load(data) }
  conf.snapshot_serializer = Proc.new { |data| Oj::dump(data) }
  conf.snapshot_deserializer = Proc.new { |data| Oj::dump(data) }
}
```

### `SandthornDriverSequel.driver_from_connection`

Creates a driver from a Sequel connection. Its possible to send in a block like the one for `configure` to chage configuration for the driver.

```ruby
driver = SandthornDriverSequel.driver_from_connection(connection: Sequel.sqlite)
```

### `SandthornDriverSequel.driver_from_url`

Creates a driver from a Sequel url. Its possible to send in a block like the one for `configure` to change configuration for the driver.

```ruby
driver = SandthornDriverSequel.driver_from_connection(url: "<sequel url string>")
```

### `SandthornDriverSequel.migrate_url`

Migrate the database based on a url string

```ruby
SandthornDriverSequel.migrate_url(url: "<sequel url string>")
```

### `SandthornDriverSequel.migrate_connection`

Migrate the database based on a connection

```ruby
SandthornDriverSequel.migrate_connection(connection: "<sequel connection>")
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
