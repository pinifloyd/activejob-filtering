require_relative './action_mailer.rb'
require_relative './job.rb'

module ActiveJob
  module Filtering
    class Arguments
      def initialize(job)
        @job = job
      end

      def call
        case
        when ActiveJob::Filtering::ActionMailer.action_mailer?(job)
          ActiveJob::Filtering::ActionMailer::Arguments.new(job).call
        else
          ActiveJob::Filtering::Job::Arguments.new(job).call
        end
      end

      private

      attr_reader :job
    end
  end
end
