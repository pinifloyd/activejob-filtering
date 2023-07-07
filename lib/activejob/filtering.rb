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

# class TestJob
#   # self.hide_arguments = false
#   # self.filter_func = -> (args) { return args } # proc func своя обработка

#   def perform(*args)
#     args = ['String', 1, 'password', { ... hash ... }, 'login', [...], User.new, hash: { user: User.new, [...]} ]
#   end
# end

# TestJob.perform(login: 'login', password: 'pass', activejob: { hide_arguments: false, filter_fields: [:login] } )

# case
# when Rails::VERSION::MAJOR <= 5
#   require 'action_dispatch/http/parameter_filter'
#   require 'active_job/logging'
# when Rails::VERSION::MAJOR > 5
#   require 'active_support/parameter_filter'
#   require 'active_job/log_subscriber'
# end

# require_relative 'filtering/version'
# require_relative 'filtering/config'
# require_relative 'filtering/settings'
# require_relative 'filtering/arguments'
# require_relative 'filtering/args_info'

# module ActiveJob
#   module Filtering
#     private

#     def args_info(job)
#       ActiveJob::Filtering::ArgsInfo.new(job.arguments).call
#     end
#   end
# end

# case
# when Rails::VERSION::MAJOR <= 5
#   ActiveJob::Logging::LogSubscriber.prepend ActiveJob::Filtering
# when Rails::VERSION::MAJOR > 5
#   ActiveJob::LogSubscriber.prepend ActiveJob::Filtering
# end

