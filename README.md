# fluent-plugin-uri-parser

[![wercker status](https://app.wercker.com/status/a735d29143f3a1a727fc65653bc81e2a/s "wercker status")](https://app.wercker.com/project/bykey/a735d29143f3a1a727fc65653bc81e2a)

This is a Fluentd plugin to parse uri and query string in log messages.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-plugin-uri-parser'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-uri-parser

## Usage

fluent-plugin-uri-parser includes 2 plugins.

* uri_parser filter plugin
* query_string_parser filter plugin

## TODO

* Write configuration sample in README.md

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/daichirata/fluent-plugin-uri-parser.

