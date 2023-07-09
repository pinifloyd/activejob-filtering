module ActiveJob
  module Filtering
    module ActionMailer
      class Arguments
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
          { filter_args: job.arguments }
        end

        private

        attr_reader :job
      end
    end
  end
end
