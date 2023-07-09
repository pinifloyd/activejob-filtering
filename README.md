# Activejob::Filtering

This is an [ActiveJob](https://github.com/rails/rails/tree/master/activejob) extension that allows to filter arguments in ActiveJob's log output.

Version: `5.2.1`. Rails: `~> 5`.

## If you using Rails >= 6.1

Rails >= 6.1 has the same features as this gem. In Rails you can disable log arguments to output like followings:

```ruby
class SensitiveJob < ApplicationJob
  self.log_arguments = false

  def perform(args)
  end
end
```

See PR: https://github.com/rails/rails/pull/37660

And PR: https://github.com/springerigor/rails/commit/02084de54d4b6c0c5861b33019a8f550b1e1ac84

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activejob-filtering', '5.2.1', github: 'pinifloyd/activejob-filtering'
```

And then execute:

    $ bundle install

## Usage

Create file `config/initializers/activejob_filtering.rb` (you can skip this step as bellow you can see settings by default).

```ruby
ActiveJob::Filtering::Config.configure do |c|
  # Available: [:show | :hide | :filter].
  c.filter_strategy = :show

  # Hash key where gem can find settings for any job.
  c.settings_key = :active_job

  # :nodoc
  c.filter_class = ActionDispatch::Http::ParameterFilter

  # :nodoc
  c.filter_fields = Rails.application.config.filter_parameters
end
```

Define your job:

```ruby
class MyJob < ApplicationJob
  def perform(*args)
  end

  # Optionaly. Setup settings for current job or mailer.
  def self.filter_settings
    {
      settings_key: :active_job,
      filter_strategy: :filter,
      filter_class: ActionDispatch::Http::ParameterFilter,
      filter_fields: Rails.application.config.filter_parameters
    }
  end
end
```

And call defined job like followings:

```ruby
MyJob.perform_later(password: 'my-password', login: 'my-login')
MyJob.perform_later(password: 'my-password', login: 'my-login', active_job: { filter_strategy: :filter })
```

Output example:

```
[ActiveJob] [MyJob] [ae3421c0-dcc7-4c3b-a741-ba06d8d68bf3] Performing MyJob (Job ID: ae3421c0-dcc7-4c3b-a741-ba06d8d68bf3) from Inline(default) enqueued at 2023-07-05T13:41:31Z WITH ARGS: {:password=>\"[FILTERED]\", :param_one=>\"some-param\"}
```

> IMPORTANT THING: gem work properly only with hash based args.

Invalid format:

```ruby
MyJob.perform_later('my-password', 'my-login')
```

Output example:

```
[ActiveJob] [MyJob] [e9bb4ca4-a1bb-4b03-a6e8-b67fb869c5d4] Performing MyJob (Job ID: e9bb4ca4-a1bb-4b03-a6e8-b67fb869c5d4) from Inline(default) enqueued at 2023-07-05T14:04:16Z WITH ARGS: ["my-password", "my-login"]
```

More examples you can find on specs.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/activejob-filtering.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## TODO

- Add filter_function (proc or lambda).