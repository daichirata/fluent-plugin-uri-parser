class Fluent::URIParserFilter < Fluent::Filter
  Fluent::Plugin.register_filter("uri_parser", self)

  config_param :key_name, :string
  config_param :hash_value_field, :string, default: nil
  config_param :json_value_field, :string, default: nil
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
    require "addressable/uri"
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
        uri = Addressable::URI.parse(raw_value)

        values = {}
        values[@out_key_scheme] = uri.scheme if @out_key_scheme
        values[@out_key_host] = uri.host if @out_key_host
        values[@out_key_port] = uri.inferred_port if @out_key_port
        values[@out_key_path] = uri.path if @out_key_path
        values[@out_key_query] = uri.query if @out_key_query
        values[@out_key_fragment] = uri.fragment if @out_key_fragment
        values.reject! {|_, v| v.nil? } if @ignore_nil

        unless values.empty?
          if @inject_key_prefix
            values = Hash[values.map{|k,v| [ @inject_key_prefix + k, v ]}]
          end

          unless @hash_value_field or @json_value_field then
            r = values
          else
            if @hash_value_field
              r = { @hash_value_field => values }
            end
            if @json_value_field
              r = { @json_value_field => values.to_json }
            end
          end

          record = record.merge(r)
        end

        new_es.add(time, record)
      rescue => e
        log.warn "parse failed #{e.message}" unless @suppress_parse_error_log
      end
    end

    new_es
  end
end
