module ActiveJob
  module Filtering
    class Arguments
      def initialize(arguments)
        @arguments = arguments.dup
      end

      def call
        return if arguments.blank?

        args, mailer = extract_mailer_arguments
        return args if mailer

        extract_job_arguments
      end

      private

      attr_accessor :arguments

      # Mailer arguments look like:
      #
      # ['MailerClass', 'method_name', 'deliver_now', { :args=>[...] }]
      def extract_mailer_arguments
        args = nil
        mailer = false

        arguments.each do |argument|
          next unless argument.is_a?(Hash)
          next unless argument.has_key?(:args)

          if argument[:args].first.is_a?(Hash)
            args = argument[:args].first
          else
            args = argument[:args]
          end

          mailer = true
          break
        end

        [args, mailer]
      end

      def extract_job_arguments
        return arguments if arguments.size > 1
        return arguments unless arguments.first.is_a?(Hash)

        arguments.first
      end
    end
  end
end
