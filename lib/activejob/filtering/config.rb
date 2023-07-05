module ActiveJob
  module Filtering
    module Config
      attr_writer :settings_key
      attr_writer :hide_arguments
      attr_writer :filter_class
      attr_writer :filter_fields

      def settings_key
        @settings_key || :active_job
      end

      def hide_arguments
        !!@hide_arguments
      end

      def filter_class
        @filter_class || ActiveSupport::ParameterFilter
      end

      def filter_fields
        return @filter_fields if @filter_fields.present?
        return Rails.application.config.filter_parameters if defined?(Rails)
        %i[passw secret token _key crypt salt certificate otp ssn]
      end

      def to_settings
        {
          hide_arguments: hide_arguments,
          filter_class: filter_class,
          filter_fields: filter_fields
        }
      end

      def configure
        yield(self)
      end

      extend(self)
    end
  end
end
