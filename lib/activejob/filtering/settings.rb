module ActiveJob
  module Filtering
    class Settings
      def initialize(arguments)
        @arguments = arguments.dup
        @settings = {}
        @defaults = ::ActiveJob::Filtering::Config.to_settings
      end

      def call
        return if arguments.blank?

        extract_mailer_settings
        return defaults.merge(settings) if settings.present?

        extract_job_settings
        defaults.merge(settings.present? ? settings : {})
      end

      private

      attr_accessor :arguments, :settings, :defaults

      # Mailer arguments look like:
      #
      # ['MailerClass', 'method_name', 'deliver_now', { :args=>[...] }]
      def extract_mailer_settings
        arguments.each do |argument|
          next unless argument.is_a?(Hash)
          next unless argument.has_key?(:args)

          argument[:args].each do |arg|
            next unless arg.is_a?(Hash)

            values = arg[::ActiveJob::Filtering::Config.settings_key]
            next if values.blank?

            @settings = values
            break
          end

          break
        end
      end

      def extract_job_settings
        arguments.each do |argument|
          next unless argument.is_a?(Hash)

          values = argument[::ActiveJob::Filtering::Config.settings_key]
          next if values.blank?

          @settings = values
          break
        end
      end
    end
  end
end
