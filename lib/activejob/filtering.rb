# frozen_string_literal: true

require 'action_dispatch/http/parameter_filter'
require 'active_job/logging'

require_relative 'filtering/version'
require_relative 'filtering/config'
require_relative 'filtering/settings'
require_relative 'filtering/arguments'
require_relative 'filtering/args_info'

module ActiveJob
  module Filtering
    private

    def args_info(job)
      ActiveJob::Filtering::ArgsInfo.new(job).call
    end
  end
end

ActiveJob::Logging::LogSubscriber.prepend ActiveJob::Filtering
