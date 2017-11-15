module Fluent
  module Plugin
    class QueryStringParserFilter < Filter
      Fluent::Plugin.register_filter("query_string_parser", self)

      config_param :key_name, :string
      config_param :hash_value_field, :string, default: nil
      config_param :inject_key_prefix, :string, default: nil
      config_param :suppress_parse_error_log, :bool, default: false
      config_param :ignore_key_not_exist, :bool, default: false
      config_param :emit_invalid_record_to_error, :bool, default: true
      config_param :multi_value_params, :bool, default: false

      def initialize
        super
        require "addressable/uri"
      end

      def filter(tag, time, record)
        raw_value = record[@key_name]

        if raw_value.nil?
          if @emit_invalid_record_to_error
            router.emit_error_event(tag, time, record, ArgumentError.new("#{@key_name} does not exist"))
          end
          return @ignore_key_not_exist ? nil : record
        end

        begin
          params = Addressable::URI.form_unencode(raw_value)

          unless params.empty?
            if @multi_value_params
              values = Hash.new {|h,k| h[k] = [] }
              params.each{|pair| values[pair[0]].push(pair[1])}
            else
              values = Hash[params]
            end

            if @inject_key_prefix
              values = Hash[values.map{|k,v| [ @inject_key_prefix + k, v ]}]
            end
            r = @hash_value_field ? { @hash_value_field => values } : values
            record = record.merge(r)
          end
        rescue => e
          log.warn "parse failed #{e.message}" unless @suppress_parse_error_log
        end

        return record
      end
    end
  end
end
