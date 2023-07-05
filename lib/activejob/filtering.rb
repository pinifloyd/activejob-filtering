# frozen_string_literal: true

require 'active_support/parameter_filter'
require 'active_job/log_subscriber'

require_relative 'filtering/version'
require_relative 'filtering/config'
require_relative 'filtering/settings'
require_relative 'filtering/arguments'
require_relative 'filtering/args_info'

module ActiveJob
  module Filtering
    private

    def args_info(job)
      ActiveJob::Filtering::ArgsInfo.new(job.arguments).call
    end
  end
end

ActiveJob::LogSubscriber.prepend ActiveJob::Filtering
