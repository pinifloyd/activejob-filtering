require_relative './action_mailer/settings.rb'
require_relative './action_mailer/arguments.rb'

module ActiveJob
  module Filtering
    module ActionMailer
      def self.action_mailer?(job)
        job.class.name.split('::').first == 'ActionMailer'
      end
    end
  end
end
