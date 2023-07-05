module ActiveJob
  module Filtering
    class ArgsInfo
      def initialize(arguments)
        @settings = ::ActiveJob::Filtering::Settings.new(arguments).call
        @arguments = ::ActiveJob::Filtering::Arguments.new(arguments).call
      end

      def call
        return '' if hide_arguments?

        begin
          message = filter_class.new(filter_fields).filter(arguments)
          " WITH ARGS: #{message}"
        rescue TypeError => _error
          " [ERROR: WRONG FORMAT] CANNOT FILTER ARGS: #{arguments.to_s}"
        end
      end

      private

      attr_accessor :arguments, :settings

      def hide_arguments?
        arguments.blank? || settings[:hide_arguments]
      end

      def filter_class
        settings[:filter_class]
      end

      def filter_fields
        settings[:filter_fields]
      end
    end
  end
end
