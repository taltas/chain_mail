![ChainMail Logo](https://raw.githubusercontent.com/taltas/chain_mail/main/assets/images/logo.png)

# ChainMail

[![Coverage Status](https://coveralls.io/repos/github/taltas/chain_mail/badge.svg?branch=main)](https://coveralls.io/github/taltas/chain_mail?branch=main)
[![Ruby](https://img.shields.io/badge/ruby-3.0+-blue.svg)](https://www.ruby-lang.org)
[![Build Status](https://github.com/taltas/chain_mail/workflows/Ruby/badge.svg)](https://github.com/taltas/chain_mail/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![RuboCop](https://img.shields.io/badge/rubocop-enabled-brightgreen.svg)](https://github.com/rubocop/rubocop)

ChainMail is a Ruby gem that ensures your transactional **emails never fail** by automatically switching between multiple email providers (SendGrid, Postmark, Mailgun, SES, etc.) when one fails to send. No more lost emails, no more manual intervention required.

## Why ChainMail?

- **Zero Downtime**: If one provider fails, emails automatically route to the next available provider
- **Easy Setup**: Simple configuration with familiar Rails patterns
- **Multiple Providers**: Built-in support for all major email services
- **Error Aggregation**: Get detailed reports on any delivery issues

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
```

## Requirements

- Ruby 3.0 or higher
- Rails 6.0+ (for Rails integration)
- Active email provider accounts (SendGrid, Postmark, etc.)

## Architecture

- **Configuration:** Set up providers and credentials in an initializer or before sending.
- **Delivery:** Handles failover, input validation, and error aggregation.
- **Providers:** Each adapter implements a standardized interface and error handling.

## Supported Email Providers

ChainMail includes built-in support for the following email providers. Here's how to configure each one in your Rails initializer:

### Amazon SES

```ruby
ChainMail.configure do |config|
  config.providers = [
    { ses: {
        region: ENV["AWS_REGION"],
        access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
      } }
  ]
end
```

### Brevo (formerly Sendinblue)

```ruby
ChainMail.configure do |config|
  config.providers = [
    { brevo: {
        api_key: ENV["BREVO_API_KEY"],
        sandbox: ENV["BREVO_SANDBOX"] == "true" # optional
      } }
  ]
end
```

### Mailgun

```ruby
ChainMail.configure do |config|
  config.providers = [
    { mailgun: {
        domain: ENV["MAILGUN_DOMAIN"],
        api_key: ENV["MAILGUN_API_KEY"]
      } }
  ]
end
```

### OneSignal

```ruby
ChainMail.configure do |config|
  config.providers = [
    { one_signal: { api_key: ENV["ONESIGNAL_API_KEY"] } }
  ]
end
```

### Postmark

```ruby
ChainMail.configure do |config|
  config.providers = [
    { postmark: { api_key: ENV["POSTMARK_API_KEY"] } }
  ]
end
```

### SendGrid

```ruby
ChainMail.configure do |config|
  config.providers = [
    { send_grid: { api_key: ENV["SENDGRID_API_KEY"] } }
  ]
end
```

### SendPulse

```ruby
ChainMail.configure do |config|
  config.providers = [
    { send_pulse: {
        client_id: ENV["SENDPULSE_CLIENT_ID"],
        client_secret: ENV["SENDPULSE_CLIENT_SECRET"]
      } }
  ]
end
```

### Multiple Providers with Priorities

```ruby
ChainMail.configure do |config|
  config.providers = [
    { send_grid: { api_key: ENV["SENDGRID_API_KEY"], priority: 1 } },
    { mailgun: {
        domain: ENV["MAILGUN_DOMAIN"],
        api_key: ENV["MAILGUN_API_KEY"],
        priority: 2
      } },
    { ses: {
        region: ENV["AWS_REGION"],
        access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
        priority: 3
      } }
  ]
end
```

**Note:** Always store API keys and credentials securely using environment variables. Providers are tried in the order listed - the first available provider will handle the email delivery.

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

Check out the repo and start developing!

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/taltas/chain_mail.
