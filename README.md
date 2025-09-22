# ChainMail

[![Coverage Status](https://coveralls.io/repos/github/torayaltas/chain_mail/badge.svg?branch=main)](https://coveralls.io/github/torayaltas/chain_mail?branch=main)

ChainMail is a Ruby gem that provides a unified interface for sending transactional emails through multiple providers (SendGrid, Postmark, Mailgun, SES, etc.) with automatic failover.

## Architecture

- **Configuration:** Set up providers and credentials in an initializer or before sending.
- **Delivery:** Handles failover, input validation, and error aggregation.
- **Providers:** Each adapter implements a standardized interface and error handling.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'chain_mail'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install chain_mail

## Usage

### Rails Setup

Add a configuration initializer at [`config/initializers/chain_mail.rb`](config/initializers/chain_mail.rb):

```ruby
ChainMail.configure do |config|
  config.providers = [
    { send_grid:  { api_key: ENV["SENDGRID_API_KEY"] } },
    { mailgun:    { domain: ENV["MAILGUN_DOMAIN"], api_key: ENV["MAILGUN_API_KEY"] } },
    # Add more providers as needed
  ]
end
```

Set the delivery method in your environment config (e.g. `config/environments/production.rb`):

```ruby
config.action_mailer.delivery_method = :chain_mail
```

Send an email using ActionMailer:

```ruby
class UserMailer < ApplicationMailer
  def welcome_email(user)
    mail(
      to: user.email,
      from: 'noreply@example.com',
      subject: 'Welcome!',
      body: 'Hello and welcome!'
    )
  end
end

# In config/environments/production.rb
config.action_mailer.delivery_method = :chain_mail
```

## Provider Priorities & Dynamic Configuration

- Providers are tried in the order listed in `config.providers`.
- You can register/unregister adapters at runtime:

```ruby
ChainMail.register_provider(:custom, CustomProviderClass)
ChainMail.unregister_provider(:send_grid)
```

- You can update provider priorities or credentials dynamically:

```ruby
ChainMail.config.providers = [
  { custom: { api_key: "CUSTOM_API_KEY" } },
  { mailgun: { domain: "MAILGUN_DOMAIN", api_key: "MAILGUN_API_KEY" } }
]
```

- API keys and credentials should be stored securely, e.g. using environment variables.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/torayaltas/chain_mail.
