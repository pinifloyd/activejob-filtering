module ActiveJob
  module Filtering
    module Job
      class Arguments
        def initialize(job)
          @job = job
        end

        def call
          { filter_args: job.arguments }
        end

        private

        attr_reader :job
      end
    end
  end
end
