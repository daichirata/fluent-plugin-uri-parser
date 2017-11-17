# coding: utf-8
require "helper"

class QueryStringParserFilterTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    @tag = "test.no.change"
    @time = Fluent::EventTime.from_time(Time.parse("2016-01-01 00:00:00"))
  end

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::QueryStringParserFilter).configure(conf)
  end

  def test_filter
    config = %[
      key_name query
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "query" => "foo=bar&hoge=fuga" })
    end
    records = d1.filtered_records

    assert_equal 1, records.length

    assert_equal "foo=bar&hoge=fuga", records[0]["query"]
    assert_equal "bar",               records[0]["foo"]
    assert_equal "fuga",              records[0]["hoge"]
  end

  def test_filter_non_ascii
    config = %[
      key_name query
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "query" => "тест=тестович" })
    end
    records = d1.filtered_records

    assert_equal 1, records.length

    assert_equal "тестович", records[0]["тест"]
  end


  def test_filter_ignore_key_not_exist
    config = %[
      key_name query
      ignore_key_not_exist true
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "query1" => "foo=bar&hoge=fuga" })
    end
    records = d1.filtered_records

    assert_equal 0, records.length
  end

  def test_filter_hash_value_field
    config = %[
      key_name query
      hash_value_field parsed
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "query" => "foo=bar&hoge=fuga" })
    end
    records = d1.filtered_records

    assert_equal 1, records.length

    assert_equal "foo=bar&hoge=fuga", records[0]["query"]
    assert_equal "bar",               records[0]["parsed"]["foo"]
    assert_equal "fuga",              records[0]["parsed"]["hoge"]
  end

  def test_filter_multi_value_params
    config = %[
      key_name query
      hash_value_field parsed
      multi_value_params true
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "query" => "foo=bar1&hoge=fuga&foo=bar2" })
    end
    records = d1.filtered_records

    assert_equal 1, records.length

    assert_equal "foo=bar1&hoge=fuga&foo=bar2", records[0]["query"]
    assert_equal ["bar1", "bar2"],              records[0]["parsed"]["foo"]
    assert_equal ["fuga"],                      records[0]["parsed"]["hoge"]
  end

  def test_filter_inject_key_prefix
    config = %[
      key_name query
      inject_key_prefix parsed.
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "query" => "foo=bar&hoge=fuga" })
    end
    records = d1.filtered_records

    assert_equal 1, records.length

    assert_equal "foo=bar&hoge=fuga", records[0]["query"]
    assert_equal "bar",               records[0]["parsed.foo"]
    assert_equal "fuga",              records[0]["parsed.hoge"]
  end
end
