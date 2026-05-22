require 'bundler/setup'
require 'test-unit'
require 'fluent/test'
require 'fluent/test/driver/filter'
require 'fluent/test/helpers'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'fluent/plugin/filter_uri_parser'
require 'fluent/plugin/filter_query_string_parser'

class Test::Unit::TestCase
  include Fluent::Test::Helpers
end
