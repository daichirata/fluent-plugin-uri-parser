require "helper"

class URIParserFilterTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    @tag = "test.no.change"
    @time = Fluent::EventTime.from_time(Time.parse("2016-01-01 00:00:00"))
  end

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::URIParserFilter).configure(conf)
  end

  def test_filter
    config = %[
      key_name url
      out_key_scheme scheme
      out_key_host host
      out_key_port port
      out_key_path path
      out_key_query query
      out_key_fragment fragment
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "url" => "http://example.com" })
      d1.feed(@time, { "url" => "https://example.com/over/there?foo=bar&hoge=fuga" })
      d1.feed(@time, { "url" => "http://example.com:8080/?id=25#time=1305212049" })
    end
    records = d1.filtered_records

    assert_equal 3, records.length

    assert_equal "http",              records[0]["scheme"]
    assert_equal "example.com",       records[0]["host"]
    assert_equal 80,                  records[0]["port"]
    assert_equal "" ,                 records[0]["path"]
    assert_equal nil,                 records[0]["query"]
    assert_equal nil,                 records[0]["fragment"]

    assert_equal "https",             records[1]["scheme"]
    assert_equal "example.com",       records[1]["host"]
    assert_equal 443,                 records[1]["port"]
    assert_equal "/over/there",       records[1]["path"]
    assert_equal "foo=bar&hoge=fuga", records[1]["query"]
    assert_equal nil,                 records[1]["fragment"]

    assert_equal "http",              records[2]["scheme"]
    assert_equal "example.com",       records[2]["host"]
    assert_equal 8080,                records[2]["port"]
    assert_equal "/",                 records[2]["path"]
    assert_equal "id=25",             records[2]["query"]
    assert_equal "time=1305212049",   records[2]["fragment"]
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
      key_name url
      hash_value_field parsed
      out_key_scheme scheme
      out_key_host host
      out_key_port port
      out_key_path path
      out_key_query query
      out_key_fragment fragment
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "url" => "https://example.com/over/there?foo=bar&hoge=fuga#time=1305212049" })
    end
    records = d1.filtered_records

    assert_equal 1, records.length

    assert_equal "https",             records[0]["parsed"]["scheme"]
    assert_equal "example.com",       records[0]["parsed"]["host"]
    assert_equal 443,                 records[0]["parsed"]["port"]
    assert_equal "/over/there",       records[0]["parsed"]["path"]
    assert_equal "foo=bar&hoge=fuga", records[0]["parsed"]["query"]
    assert_equal "time=1305212049",   records[0]["parsed"]["fragment"]
  end

  def test_filter_inject_key_prefix
    config = %[
      key_name url
      inject_key_prefix parsed.
      out_key_scheme scheme
      out_key_host host
      out_key_port port
      out_key_path path
      out_key_query query
      out_key_fragment fragment
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "url" => "https://example.com/over/there?foo=bar&hoge=fuga#time=1305212049" })
    end
    records = d1.filtered_records

    assert_equal 1, records.length

    assert_equal "https",             records[0]["parsed.scheme"]
    assert_equal "example.com",       records[0]["parsed.host"]
    assert_equal 443,                 records[0]["parsed.port"]
    assert_equal "/over/there",       records[0]["parsed.path"]
    assert_equal "foo=bar&hoge=fuga", records[0]["parsed.query"]
    assert_equal "time=1305212049",   records[0]["parsed.fragment"]
  end

  def test_filter_ignore_nil
    config = %[
      key_name url
      ignore_nil true
      out_key_scheme scheme
      out_key_host host
      out_key_port port
      out_key_path path
      out_key_query query
      out_key_fragment fragment
    ]

    d1 = create_driver(config)
    d1.run(default_tag: @tag) do
      d1.feed(@time, { "url" => "https://example.com/over/there" })
    end
    records = d1.filtered_records

    assert_equal 1, records.length

    assert_equal "https",        records[0]["scheme"]
    assert_equal "example.com",  records[0]["host"]
    assert_equal 443,            records[0]["port"]
    assert_equal "/over/there",  records[0]["path"]

    assert_not_include records[0].keys, "query"
    assert_not_include records[0].keys, "fragment"
  end
end
