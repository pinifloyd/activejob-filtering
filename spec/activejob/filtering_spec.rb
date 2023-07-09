require 'rails'

RSpec.describe ActiveJob::Filtering do
  before do
    @io = StringIO.new
    ActiveJob::Base.logger = ActiveSupport::TaggedLogging.new(Logger.new(@io))

    allow(Rails).to receive_message_chain(
      :application, :config, :filter_parameters
    ).and_return(
      %i[password otp one_time_password token code authorization_code access_token refresh_token]
    )
  end

  def output
    @io.tap(&:rewind).read
  end

  context 'mailer' do
    before do
      class UserMailer < ActionMailer::Base
        default from: 'test@example.com'

        if self.respond_to?('filter_settings')
          singleton_class.undef_method('filter_settings')
        end

        def send_named(login:, password:)
          mail to: 'admin@example.com', subject: 'Test email.', body: ''
        end

        def send_hash(hash)
          mail to: 'admin@example.com', subject: 'Test email.', body: ''
        end

        def send_values(login, password)
          mail to: 'admin@example.com', subject: 'Test email.', body: ''
        end
      end
    end

    context 'default filtering settings' do
      context 'should show' do
        before do
          ActiveJob::Filtering::Config.filter_strategy = :show
        end

        it 'named args' do
          UserMailer.send_named(login: 'my-login', password: 'my-password').deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/:password=>"my-password"/)
          expect(output).to match(/:login=>"my-login"/)
        end

        it 'hash arg' do
          UserMailer.send_hash({ login: 'my-login', password: 'my-password' }).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/:password=>"my-password"/)
          expect(output).to match(/:login=>"my-login"/)
        end

        it 'values arg' do
          UserMailer.send_values('my-login', 'my-password').deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/my-password/)
          expect(output).to match(/my-login/)
        end
      end

      context 'should hide' do
        before do
          ActiveJob::Filtering::Config.filter_strategy = :hide
        end

        it 'named args' do
          UserMailer.send_named(login: 'my-login', password: 'my-password').deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'hash arg' do
          UserMailer.send_hash({ login: 'my-login', password: 'my-password' }).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'values arg' do
          UserMailer.send_values('my-login', 'my-password').deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end
      end

      context 'should filter' do
        before do
          ActiveJob::Filtering::Config.filter_strategy = :filter
        end

        it 'named args' do
          UserMailer.send_named(login: 'my-login', password: 'my-password').deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:filter)
          expect(output).to match(/:password=>"\[FILTERED\]"/)
          expect(output).to match(/:login=>"my-login"/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'hash args' do
          UserMailer.send_hash({ login: 'my-login', password: 'my-password' }).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:filter)
          expect(output).to match(/:password=>"\[FILTERED\]"/)
          expect(output).to match(/:login=>"my-login"/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'values args (work as raw)' do
          UserMailer.send_values('my-login', 'my-password').deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:filter)
          expect(output).to match(/my-password/)
          expect(output).to match(/my-login/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end
      end
    end

    context 'class filtering settings' do
      context 'should show' do
        before do
          UserMailer.instance_eval do
            def filter_settings
              { filter_strategy: :show }
            end
          end

          ActiveJob::Filtering::Config.filter_strategy = :hide
        end

        it 'named args' do
          UserMailer.send_named(login: 'my-login', password: 'my-password').deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(UserMailer.filter_settings[:filter_strategy]).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/:password=>"my-password"/)
          expect(output).to match(/:login=>"my-login"/)
        end

        it 'hash args' do
          UserMailer.send_hash({ login: 'my-login', password: 'my-password' }).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(UserMailer.filter_settings[:filter_strategy]).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/:password=>"my-password"/)
          expect(output).to match(/:login=>"my-login"/)
        end

        it 'values args' do
          UserMailer.send_values('my-login', 'my-password').deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(UserMailer.filter_settings[:filter_strategy]).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/"my-password"/)
          expect(output).to match(/"my-login"/)
        end
      end

      context 'should hide' do
        before do
          UserMailer.instance_eval do
            def filter_settings
              { filter_strategy: :hide }
            end
          end

          ActiveJob::Filtering::Config.filter_strategy = :show
        end

        it 'named args' do
          UserMailer.send_named(login: 'my-login', password: 'my-password').deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(UserMailer.filter_settings[:filter_strategy]).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'hash args' do
          UserMailer.send_hash({ login: 'my-login', password: 'my-password' }).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(UserMailer.filter_settings[:filter_strategy]).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'values args' do
          UserMailer.send_values('my-login', 'my-password').deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(UserMailer.filter_settings[:filter_strategy]).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end
      end

      context 'should filter' do
        before do
          UserMailer.instance_eval do
            def filter_settings
              { filter_strategy: :filter }
            end
          end

          ActiveJob::Filtering::Config.filter_strategy = :show
        end

        it 'named args' do
          UserMailer.send_named(login: 'my-login', password: 'my-password').deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(UserMailer.filter_settings[:filter_strategy]).to eql(:filter)
          expect(output).to match(/:password=>"\[FILTERED\]"/)
          expect(output).to match(/:login=>"my-login"/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'hash args' do
          UserMailer.send_hash({ login: 'my-login', password: 'my-password' }).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(UserMailer.filter_settings[:filter_strategy]).to eql(:filter)
          expect(output).to match(/:password=>"\[FILTERED\]"/)
          expect(output).to match(/:login=>"my-login"/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'values args (work as raw)' do
          UserMailer.send_values('my-login', 'my-password').deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(UserMailer.filter_settings[:filter_strategy]).to eql(:filter)
          expect(output).to match(/my-password/)
          expect(output).to match(/my-login/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end
      end
    end

    context 'params filtering settings' do
      before do
        UserMailer.class_eval do
          def send_named(login:, password:, active_job:)
            mail to: 'admin@example.com', subject: 'Test email.', body: ''
          end

          def send_values(login, password, settings)
            mail to: 'admin@example.com', subject: 'Test email.', body: ''
          end
        end
      end

      context 'should show' do
        before do
          ActiveJob::Filtering::Config.filter_strategy = :hide
        end

        it 'named args' do
          UserMailer.send_named(
            login: 'my-login',
            password: 'my-password',
            active_job: {
              filter_strategy: 'show'
            }
          ).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/:password=>"my-password"/)
          expect(output).to match(/:login=>"my-login"/)
        end

        it 'hash args' do
          UserMailer.send_hash({
            login: 'my-login',
            password: 'my-password',
            active_job: {
              filter_strategy: 'show'
            }
          }).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/:password=>"my-password"/)
          expect(output).to match(/:login=>"my-login"/)
        end

        it 'values args' do
          UserMailer.send_values(
            'my-login',
            'my-password',
            active_job: {
              filter_strategy: 'show'
            }
          ).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/"my-password"/)
          expect(output).to match(/"my-login"/)
        end
      end

      context 'should hide' do
        before do
          ActiveJob::Filtering::Config.filter_strategy = :show
        end

        it 'named args' do
          UserMailer.send_named(
            login: 'my-login',
            password: 'my-password',
            active_job: {
              filter_strategy: 'hide'
            }
          ).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'hash args' do
          UserMailer.send_hash({
            login: 'my-login',
            password: 'my-password',
            active_job: {
              filter_strategy: 'hide'
            }
          }).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'values args' do
          UserMailer.send_values(
            'my-login',
            'my-password',
            active_job: {
              filter_strategy: 'hide'
            }
          ).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end
      end

      context 'should filter' do
        before do
          ActiveJob::Filtering::Config.filter_strategy = :show
        end

        it 'named args' do
          UserMailer.send_named(
            login: 'my-login',
            password: 'my-password',
            active_job: {
              filter_strategy: 'filter'
            }
          ).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).to match(/:password=>"\[FILTERED\]"/)
          expect(output).to match(/:login=>"my-login"/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'hash args' do
          UserMailer.send_hash({
            login: 'my-login',
            password: 'my-password',
            active_job: {
              filter_strategy: 'filter'
            }
          }).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).to match(/:password=>"\[FILTERED\]"/)
          expect(output).to match(/:login=>"my-login"/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'values args (work as raw)' do
          UserMailer.send_values(
            'my-login',
            'my-password',
            active_job: {
              filter_strategy: 'filter'
            }
          ).deliver_later

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).to match(/"my-password"/)
          expect(output).to match(/"my-login"/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end
      end
    end
  end

  context 'job' do
    before do
      class TestJob < ActiveJob::Base
        if self.respond_to?('filter_settings')
          singleton_class.undef_method('filter_settings')
        end

        def perform(*args)
        end
      end
    end

    context 'default filtering settings' do
      context 'should show' do
        before do
          ActiveJob::Filtering::Config.filter_strategy = :show
        end

        it 'named args' do
          TestJob.perform_later(login: 'my-login', password: 'my-password')

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/:password=>"my-password"/)
          expect(output).to match(/:login=>"my-login"/)
        end

        it 'hash arg' do
          TestJob.perform_later({ login: 'my-login', password: 'my-password' })

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/:password=>"my-password"/)
          expect(output).to match(/:login=>"my-login"/)
        end

        it 'values arg' do
          TestJob.perform_later('my-login', 'my-password')

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/my-password/)
          expect(output).to match(/my-login/)
        end
      end

      context 'should hide' do
        before do
          ActiveJob::Filtering::Config.filter_strategy = :hide
        end

        it 'named args' do
          TestJob.perform_later(login: 'my-login', password: 'my-password')

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'hash arg' do
          TestJob.perform_later({ login: 'my-login', password: 'my-password' })

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'values arg' do
          TestJob.perform_later('my-login', 'my-password')

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end
      end

      context 'should filter' do
        before do
          ActiveJob::Filtering::Config.filter_strategy = :filter
        end

        it 'named args' do
          TestJob.perform_later(login: 'my-login', password: 'my-password')

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:filter)
          expect(output).to match(/:password=>"\[FILTERED\]"/)
          expect(output).to match(/:login=>"my-login"/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'hash args' do
          TestJob.perform_later({ login: 'my-login', password: 'my-password' })

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:filter)
          expect(output).to match(/:password=>"\[FILTERED\]"/)
          expect(output).to match(/:login=>"my-login"/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'values args (work as raw)' do
          TestJob.perform_later('my-login', 'my-password')

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:filter)
          expect(output).to match(/my-password/)
          expect(output).to match(/my-login/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end
      end
    end

    context 'class filtering settings' do
      context 'should show' do
        before do
          TestJob.instance_eval do
            def filter_settings
              { filter_strategy: :show }
            end
          end

          ActiveJob::Filtering::Config.filter_strategy = :hide
        end

        it 'named args' do
          TestJob.perform_later(login: 'my-login', password: 'my-password')

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(TestJob.filter_settings[:filter_strategy]).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/:password=>"my-password"/)
          expect(output).to match(/:login=>"my-login"/)
        end

        it 'hash args' do
          TestJob.perform_later({ login: 'my-login', password: 'my-password' })

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(TestJob.filter_settings[:filter_strategy]).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/:password=>"my-password"/)
          expect(output).to match(/:login=>"my-login"/)
        end

        it 'values args' do
          TestJob.perform_later('my-login', 'my-password')

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(TestJob.filter_settings[:filter_strategy]).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/"my-password"/)
          expect(output).to match(/"my-login"/)
        end
      end

      context 'should hide' do
        before do
          TestJob.instance_eval do
            def filter_settings
              { filter_strategy: :hide }
            end
          end

          ActiveJob::Filtering::Config.filter_strategy = :show
        end

        it 'named args' do
          TestJob.perform_later(login: 'my-login', password: 'my-password')

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(TestJob.filter_settings[:filter_strategy]).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'hash args' do
          TestJob.perform_later({ login: 'my-login', password: 'my-password' })

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(TestJob.filter_settings[:filter_strategy]).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'values args' do
          TestJob.perform_later('my-login', 'my-password')

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(TestJob.filter_settings[:filter_strategy]).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end
      end

      context 'should filter' do
        before do
          TestJob.instance_eval do
            def filter_settings
              { filter_strategy: :filter }
            end
          end

          ActiveJob::Filtering::Config.filter_strategy = :show
        end

        it 'named args' do
          TestJob.perform_later(login: 'my-login', password: 'my-password')

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(TestJob.filter_settings[:filter_strategy]).to eql(:filter)
          expect(output).to match(/:password=>"\[FILTERED\]"/)
          expect(output).to match(/:login=>"my-login"/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'hash args' do
          TestJob.perform_later({ login: 'my-login', password: 'my-password' })

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(TestJob.filter_settings[:filter_strategy]).to eql(:filter)
          expect(output).to match(/:password=>"\[FILTERED\]"/)
          expect(output).to match(/:login=>"my-login"/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'values args (work as raw)' do
          TestJob.perform_later('my-login', 'my-password')

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(TestJob.filter_settings[:filter_strategy]).to eql(:filter)
          expect(output).to match(/my-password/)
          expect(output).to match(/my-login/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end
      end
    end

    context 'params filtering settings' do
      context 'should show' do
        before do
          ActiveJob::Filtering::Config.filter_strategy = :hide
        end

        it 'named args' do
          TestJob.perform_later(
            login: 'my-login',
            password: 'my-password',
            active_job: {
              filter_strategy: 'show'
            }
          )

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/:password=>"my-password"/)
          expect(output).to match(/:login=>"my-login"/)
        end

        it 'hash args' do
          TestJob.perform_later({
            login: 'my-login',
            password: 'my-password',
            active_job: {
              filter_strategy: 'show'
            }
          })

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/:password=>"my-password"/)
          expect(output).to match(/:login=>"my-login"/)
        end

        it 'values args' do
          TestJob.perform_later(
            'my-login',
            'my-password',
            active_job: {
              filter_strategy: 'show'
            }
          )

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:hide)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
          expect(output).to match(/"my-password"/)
          expect(output).to match(/"my-login"/)
        end
      end

      context 'should hide' do
        before do
          ActiveJob::Filtering::Config.filter_strategy = :show
        end

        it 'named args' do
          TestJob.perform_later(
            login: 'my-login',
            password: 'my-password',
            active_job: {
              filter_strategy: 'hide'
            }
          )

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'hash args' do
          TestJob.perform_later({
            login: 'my-login',
            password: 'my-password',
            active_job: {
              filter_strategy: 'hide'
            }
          })

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'values args' do
          TestJob.perform_later(
            'my-login',
            'my-password',
            active_job: {
              filter_strategy: 'hide'
            }
          )

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).not_to match(/\[FILTERED\]/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/password/)
          expect(output).not_to match(/login/)
          expect(output).to match(/WITH ARGS: \[HIDDEN\]/)
        end
      end

      context 'should filter' do
        before do
          ActiveJob::Filtering::Config.filter_strategy = :show
        end

        it 'named args' do
          TestJob.perform_later(
            login: 'my-login',
            password: 'my-password',
            active_job: {
              filter_strategy: 'filter'
            }
          )

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).to match(/:password=>"\[FILTERED\]"/)
          expect(output).to match(/:login=>"my-login"/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'hash args' do
          TestJob.perform_later({
            login: 'my-login',
            password: 'my-password',
            active_job: {
              filter_strategy: 'filter'
            }
          })

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).to match(/:password=>"\[FILTERED\]"/)
          expect(output).to match(/:login=>"my-login"/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end

        it 'values args (work as raw)' do
          TestJob.perform_later(
            'my-login',
            'my-password',
            active_job: {
              filter_strategy: 'filter'
            }
          )

          expect(ActiveJob::Filtering::Config.filter_strategy).to eql(:show)
          expect(output).to match(/"my-password"/)
          expect(output).to match(/"my-login"/)
          expect(output).not_to match(/\[ERROR: WRONG FORMAT\] CANNOT FILTER ARGS/)
          expect(output).not_to match(/WITH ARGS: \[HIDDEN\]/)
        end
      end
    end
  end
end
