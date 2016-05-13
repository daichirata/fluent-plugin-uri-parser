require "helper"

class QueryStringParserFilterTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    @time = Time.parse("2016-01-01 00:00:00").to_i
  end

  def create_driver(conf, tag = "test")
    Fluent::Test::FilterTestDriver.new(Fluent::QueryStringParserFilter, tag).configure(conf)
  end

  def test_filter
    config = %[
      key_name query
    ]

    d1 = create_driver(config, "test.no.change")
    d1.run do
      d1.filter({ "query" => "foo=bar&hoge=fuga" }, @time)
    end
    filtered = d1.filtered_as_array

    data = filtered[0][2]
    assert_equal "foo=bar&hoge=fuga", data["query"]
    assert_equal "bar", data["foo"]
    assert_equal "fuga", data["hoge"]
  end

  def test_filter_hash_value_field
    config = %[
      key_name query
      hash_value_field parsed
    ]

    d1 = create_driver(config, "test.no.change")
    d1.run do
      d1.filter({ "query" => "foo=bar&hoge=fuga" }, @time)
    end
    filtered = d1.filtered_as_array

    data = filtered[0][2]
    assert_equal "foo=bar&hoge=fuga", data["query"]
    assert_equal "bar", data["parsed"]["foo"]
    assert_equal "fuga", data["parsed"]["hoge"]
  end

  def test_filter_inject_key_prefix
    config = %[
      key_name query
      inject_key_prefix parsed.
    ]

    d1 = create_driver(config, "test.no.change")
    d1.run do
      d1.filter({ "query" => "foo=bar&hoge=fuga" }, @time)
    end
    filtered = d1.filtered_as_array

    data = filtered[0][2]
    assert_equal "foo=bar&hoge=fuga", data["query"]
    assert_equal "bar", data["parsed.foo"]
    assert_equal "fuga", data["parsed.hoge"]
  end
end
