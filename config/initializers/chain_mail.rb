# frozen_string_literal: true

# ChainMail configuration initializer for Rails

# Configure your email providers and credentials here.
ChainMail.configure do |config|
  config.providers = [
    { send_grid: { api_key: ENV.fetch("SENDGRID_API_KEY", nil) } },
    { mailgun: { domain: ENV.fetch("MAILGUN_DOMAIN", nil),
                 api_key: ENV.fetch("MAILGUN_API_KEY", nil) } }
    # Add more providers as needed
  ]
end

# Set delivery method in environment config (e.g. config/environments/production.rb):
# config.action_mailer.delivery_method = :chain_mail
