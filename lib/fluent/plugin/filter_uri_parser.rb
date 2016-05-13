class Fluent::URIParserFilter < Fluent::Filter
  Fluent::Plugin.register_filter("uri_parser", self)

  DEFAULT_PORT_MAP = {
    "http" => 80,
    "https" => 443
  }

  config_param :key_name, :string
  config_param :hash_value_field, :string, default: nil
  config_param :inject_key_prefix, :string, default: nil
  config_param :suppress_parse_error_log, :bool, default: false
  config_param :ignore_key_not_exist, :bool, default: false
  config_param :ignore_nil, :bool, default: false

  config_param :out_key_scheme, :string, default: nil
  config_param :out_key_host, :string, default: nil
  config_param :out_key_port, :string, default: nil
  config_param :out_key_path, :string, default: nil
  config_param :out_key_query, :string, default: nil
  config_param :out_key_fragment, :string, default: nil

  def initialize
    super
    require "uri"
  end

  def filter_stream(tag, es)
    new_es = Fluent::MultiEventStream.new

    es.each do |time, record|
      raw_value = record[@key_name]
      if raw_value.nil?
        new_es.add(time, record) unless @ignore_key_not_exist
        next
      end

      begin
        scheme, host, port, path, query, fragment = parse_uri(raw_value)

        values = {}
        values[@out_key_scheme] = scheme if @out_key_scheme
        values[@out_key_host] = host if @out_key_host
        values[@out_key_port] = port if @out_key_port
        values[@out_key_path] = path if @out_key_path
        values[@out_key_query] = query if @out_key_query
        values[@out_key_fragment] = fragment if @out_key_fragment
        values.reject! {|_, v| v.nil? } if @ignore_nil

        unless values.empty?
          if @inject_key_prefix
            values = Hash[values.map{|k,v| [ @inject_key_prefix + k, v ]}]
          end
          r = @hash_value_field ? { @hash_value_field => values } : values
          record = record.merge(r)
        end

        new_es.add(time, record)
      rescue => e
        log.warn "parse failed #{e.message}" unless @suppress_parse_error_log
      end
    end

    new_es
  end

  private

  def parse_uri(uri)
    # URI.parse is useful, but it's very slow.
    scheme, _, host, port, _, path, _, query, fragment = URI.split(uri)
    port = port.nil? ? DEFAULT_PORT_MAP[scheme] : port.to_i

    [scheme, host, port, path, query, fragment]
  end
end
