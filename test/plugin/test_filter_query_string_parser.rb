# coding: utf-8
require "helper"

class QueryStringParserFilterTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    @tag = "test.no.change"
    @time = event_time("2016-01-01 00:00:00")
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

  def test_filter_drops_empty_keys
    config = %[
      key_name query
      hash_value_field parsed
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "query" => "&partnerid=12345" })
      d1.feed(@time, { "query" => "=value&foo=bar" })
      d1.feed(@time, { "query" => "&&foo=bar&&" })
      d1.feed(@time, { "query" => "foo=&bar=baz" })
    end
    records = d1.filtered_records

    assert_equal 4, records.length

    assert_equal({ "partnerid" => "12345" }, records[0]["parsed"])
    assert_equal({ "foo" => "bar" },         records[1]["parsed"])
    assert_equal({ "foo" => "bar" },         records[2]["parsed"])
    assert_equal({ "foo" => "", "bar" => "baz" }, records[3]["parsed"])
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

  def test_filter_multi_value_param_names
    config = %[
      key_name query
      hash_value_field parsed
      multi_value_param_names foo
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "query" => "foo=bar1&hoge=fuga&foo=bar2" })
    end
    records = d1.filtered_records

    assert_equal 1, records.length
    assert_equal ["bar1", "bar2"], records[0]["parsed"]["foo"]
    assert_equal "fuga",           records[0]["parsed"]["hoge"]
  end

  def test_filter_multi_value_param_names_with_single_occurrence
    config = %[
      key_name query
      hash_value_field parsed
      multi_value_param_names foo,bar
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "query" => "foo=1&bar=2&hoge=fuga" })
    end
    records = d1.filtered_records

    assert_equal 1, records.length
    assert_equal ["1"],   records[0]["parsed"]["foo"]
    assert_equal ["2"],   records[0]["parsed"]["bar"]
    assert_equal "fuga",  records[0]["parsed"]["hoge"]
  end

  def test_filter_multi_value_params_takes_precedence_over_names
    config = %[
      key_name query
      hash_value_field parsed
      multi_value_params true
      multi_value_param_names foo
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "query" => "foo=bar1&hoge=fuga&foo=bar2" })
    end
    records = d1.filtered_records

    assert_equal 1, records.length
    assert_equal ["bar1", "bar2"], records[0]["parsed"]["foo"]
    assert_equal ["fuga"],         records[0]["parsed"]["hoge"]
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

  def test_filter_emit_invalid_record_to_error_on_missing_key
    config = %[
      key_name query
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "other" => "foo=bar" })
    end

    assert_equal 1, d1.error_events.length
    tag, _time, record, error = d1.error_events.first
    assert_equal @tag, tag
    assert_equal({ "other" => "foo=bar" }, record)
    assert_kind_of ArgumentError, error
  end

  def test_filter_parse_error_is_swallowed
    config = %[
      key_name query
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "query" => 12345 })
    end
    records = d1.filtered_records

    assert_equal 1, records.length
    assert_equal({ "query" => 12345 }, records[0])
  end

  def test_filter_suppress_parse_error_log
    config = %[
      key_name query
      suppress_parse_error_log true
    ]

    d1 = create_driver(config)
    assert_nothing_raised do
      d1.run(default_tag: @tag) do
        d1.feed(@time, { "query" => 12345 })
      end
    end

    assert_equal 1, d1.filtered_records.length
  end
end
