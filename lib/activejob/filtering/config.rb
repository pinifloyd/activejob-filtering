module ActiveJob
  module Filtering
    module Config
      attr_writer :filter_strategy,
                  :filter_keys,
                  :filter_class,
                  :filter_settings_key

      # [show | hide | filter]
      def filter_strategy
        @filter_strategy || :show
      end

      def filter_class
        @filter_class || ActionDispatch::Http::ParameterFilter
      end

      def filter_keys
        @filter_keys || Rails.application.config.filter_parameters
      end

      def filter_settings_key
        @filter_settings_key || :active_job
      end

      def to_h
        {
          filter_strategy: filter_strategy,
          filter_class: filter_class,
          filter_keys: filter_keys,
          filter_settings_key: filter_settings_key
        }
      end
      alias_method :to_hash, :to_h

      def configure
        yield(self)
      end

      extend(self)
    end
  end
end
