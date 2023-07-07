module ActiveJob
  module Filtering
    module ActionMailer
      class Settings
        def initialize(job)
          @job = job
        end

        # Job example:
        #
        # <ActionMailer::DeliveryJob:0x00007f955a4f0be0
        #   @arguments=["UserMailer", "password", "deliver_now", {:login=>"my-login", :password=>"my-password"}],
        #   @job_id="e7782ef1-f42a-4014-a5ea-c917e458e53a",
        #   @queue_name="mailers",
        #   @priority=nil,
        #   @executions=0,
        #   @provider_job_id="1ded9177-2990-4bd5-b548-ef4be536a31e">
        #
        # Priority: params | klass | default settings
        def call
          default_settings = ActiveJob::Filtering::Config.to_hash
          klass_settings = extract_klass_settings
          params_settings = extract_params_settings(default_settings, klass_settings)

          default_settings.merge(klass_settings).merge(params_settings)
        end

        private

        attr_reader :job

        def extract_klass_settings
          klass = job.arguments.first.safe_constantize

          if klass.respond_to?(:filter_settings)
            klass.filter_settings
          else
            {}
          end
        end

        def extract_params_settings(default_settings, klass_settings)
          settings_key = klass_settings[:filter_settings_key]
          settings_key ||= default_settings[:filter_settings_key]

          settings = {}

          job.arguments.each do |argument|
            next unless argument.is_a?(Hash)
            next unless argument.has_key?(settings_key)

            settings = argument[settings_key]
            break
          end

          settings
        end
      end
    end
  end
end
