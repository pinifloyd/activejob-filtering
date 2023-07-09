module ActiveJob
  module Filtering
    class ArgsInfo
      class InvalidStrategy < StandardError
      end

      def initialize(job)
        @settings = ActiveJob::Filtering::Settings.new(job).call
        @arguments = ActiveJob::Filtering::Arguments.new(job).call
      end

      def call
        case settings[:filter_strategy].to_sym
        when :hide
          ' WITH ARGS: [HIDDEN]'
        when :show
          " WITH ARGS: #{arguments.to_s}"
        when :filter
          " WITH ARGS: #{filter_class.new(filter_keys).filter(arguments)}"
        else
          raise InvalidStrategy, 'Invalid strategy!'
        end
      rescue TypeError => _error
        " [ERROR: WRONG FORMAT] CANNOT FILTER ARGS: #{arguments.to_s}"
      end

      private

      attr_reader :settings, :arguments

      def filter_class
        settings[:filter_class]
      end

      def filter_keys
        settings[:filter_keys]
      end
    end
  end
end
