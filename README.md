# Fourtrack

A gem for massive, parallel recording of streaming event logs for later replay. You know when you need one.

## Usage

To record **all of your SQL:**

```ruby
recorder = Fourtrack::Recorder.new(output_path: Rails.root.join('log/sql.jsonlines.gz'), flush_after: 1024)
ActiveSupport::Notifications.subscribe('sql.active_record') do |_, started, finished, id, payload|
  recorder << JSON.dump(payload)
end
```

and to replay later:

```ruby
File.open(Rails.root.join('log/sql.jsonlines.gz')) do |f|
  player = Fourtrac::Player.new(f)
  player.each_line do |line|
    puts JSON.load(line)
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fourtrack'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fourtrack

## Development

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/WeTransfer/fourtrack.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

