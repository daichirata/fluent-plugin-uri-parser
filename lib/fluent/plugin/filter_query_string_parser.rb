class Fluent::QueryStringParserFilter < Fluent::Filter
  Fluent::Plugin.register_filter("query_string_parser", self)

  config_param :key_name, :string
  config_param :hash_value_field, :string, default: nil
  config_param :inject_key_prefix, :string, default: nil
  config_param :suppress_parse_error_log, :bool, default: false
  config_param :ignore_key_not_exist, :bool, default: false

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
        values = Hash[URI.decode_www_form(raw_value)]

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
end
