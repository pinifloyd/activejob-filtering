# frozen_string_literal: true

class TestJob < ActiveJob::Base
  def perform(*args)
  end
end

RSpec.describe ActiveJob::Filtering do
  it 'has a version number' do
    expect(ActiveJob::Filtering::VERSION).not_to be nil
  end

  before do
    @io = StringIO.new
    ActiveJob::Base.logger = ActiveSupport::TaggedLogging.new(Logger.new(@io))
  end

  def output
    @io.tap(&:rewind).read
  end

  context 'mailer' do
    it 'log empty string if args is empty' do
      TestJob.perform_later(
        'ApplicationMailer', 'send_hash', 'deliver_now', { args: [] }
      )
      expect(output).not_to match(/\[FILTERED\]/)
      expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
    end

    it 'log args if broken format' do
      TestJob.perform_later(
        'ApplicationMailer', 'send_hash', 'deliver_now', { args: %w[password login phone full-name] }
      )
      expect(output).not_to match(/\[FILTERED\]/)
      expect(output).to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
    end

    it 'log filtered args' do
      TestJob.perform_later(
        'ApplicationMailer', 'send_hash', 'deliver_now', { args: [
          { password: 'my-password', login: 'my-login' }
        ] }
      )
      expect(output).to match(/:password=>"\[FILTERED\]"/)
      expect(output).to match(/:login=>"my-login"/)
    end
  end

  context 'job' do
    it 'log empty string if args is empty' do
      TestJob.perform_later
      expect(output).not_to match(/\[FILTERED\]/)
      expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
    end

    it 'log args if broken format' do
      TestJob.perform_later('password', 'login', 'phone', 'full-name')
      expect(output).not_to match(/\[FILTERED\]/)
      expect(output).to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
    end

    it 'log filtered args' do
      TestJob.perform_later(password: 'my-password', login: 'my-login')
      expect(output).to match(/:password=>"\[FILTERED\]"/)
      expect(output).to match(/:login=>"my-login"/)
    end
  end
end
