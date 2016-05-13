require "helper"

class URIParserFilterTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    @time = Time.parse("2016-01-01 00:00:00").to_i
  end

  def create_driver(conf, tag = "test")
    Fluent::Test::FilterTestDriver.new(Fluent::URIParserFilter, tag).configure(conf)
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

    d1 = create_driver(config, "test.no.change")
    d1.run do
      d1.filter({ "url" => "http://example.com" }, @time)
      d1.filter({ "url" => "https://example.com/over/there?foo=bar&hoge=fuga" }, @time)
      d1.filter({ "url" => "http://example.com/?id=25#time=1305212049" }, @time)
    end
    filtered = d1.filtered_as_array
    assert_equal 3, filtered.length

    data = filtered[0][2]
    assert_equal "http",        data["scheme"]
    assert_equal "example.com", data["host"]
    assert_equal 80,            data["port"]
    assert_equal "" ,           data["path"]
    assert_equal nil,           data["query"]
    assert_equal nil,           data["fragment"]

    data = filtered[1][2]
    assert_equal "https",             data["scheme"]
    assert_equal "example.com",       data["host"]
    assert_equal 443,                 data["port"]
    assert_equal "/over/there",       data["path"]
    assert_equal "foo=bar&hoge=fuga", data["query"]
    assert_equal nil,                 data["fragment"]

    data = filtered[2][2]
    assert_equal "http",            data["scheme"]
    assert_equal "example.com",     data["host"]
    assert_equal 80,                data["port"]
    assert_equal "/",               data["path"]
    assert_equal "id=25",           data["query"]
    assert_equal "time=1305212049", data["fragment"]
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

    d1 = create_driver(config, "test.no.change")
    d1.run do
      d1.filter({ "url" => "https://example.com/over/there?foo=bar&hoge=fuga#time=1305212049" }, @time)
    end
    filtered = d1.filtered_as_array

    data = filtered[0][2]
    assert_equal "https",             data["parsed"]["scheme"]
    assert_equal "example.com",       data["parsed"]["host"]
    assert_equal 443,                 data["parsed"]["port"]
    assert_equal "/over/there",       data["parsed"]["path"]
    assert_equal "foo=bar&hoge=fuga", data["parsed"]["query"]
    assert_equal "time=1305212049",   data["parsed"]["fragment"]
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

    d1 = create_driver(config, "test.no.change")
    d1.run do
      d1.filter({ "url" => "https://example.com/over/there?foo=bar&hoge=fuga#time=1305212049" }, @time)
    end
    filtered = d1.filtered_as_array

    data = filtered[0][2]
    assert_equal "https",             data["parsed.scheme"]
    assert_equal "example.com",       data["parsed.host"]
    assert_equal 443,                 data["parsed.port"]
    assert_equal "/over/there",       data["parsed.path"]
    assert_equal "foo=bar&hoge=fuga", data["parsed.query"]
    assert_equal "time=1305212049",   data["parsed.fragment"]
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

    d1 = create_driver(config, "test.no.change")
    d1.run do
      d1.filter({ "url" => "https://example.com/over/there" }, @time)
    end
    filtered = d1.filtered_as_array

    data = filtered[0][2]
    assert_equal "https",        data["scheme"]
    assert_equal "example.com",  data["host"]
    assert_equal 443,            data["port"]
    assert_equal "/over/there",  data["path"]
    assert_not_include data.keys, "query"
    assert_not_include data.keys, "fragment"
  end
end
