# frozen_string_literal: true

require "chain_mail/version"
require "chain_mail/configuration"

module ChainMail
  autoload :Delivery, "chain_mail/delivery"
  autoload :Railtie, "chain_mail/railtie" if defined?(Rails)

  module Providers
    autoload :Base, "chain_mail/providers/base"
    autoload :Brevo, "chain_mail/providers/brevo"
    autoload :SendGrid, "chain_mail/providers/send_grid"
    autoload :Postmark, "chain_mail/providers/postmark"
    autoload :SES, "chain_mail/providers/ses"
    autoload :Mailgun, "chain_mail/providers/mailgun"
    autoload :SendPulse, "chain_mail/providers/send_pulse"
    autoload :OneSignal, "chain_mail/providers/one_signal"
  end

  class Error < StandardError; end

  # Provider registry for dynamic adapter management
  @provider_registry = {
    brevo: Providers::Brevo,
    send_grid: Providers::SendGrid,
    postmark: Providers::Postmark,
    ses: Providers::SES,
    mailgun: Providers::Mailgun,
    send_pulse: Providers::SendPulse,
    one_signal: Providers::OneSignal
  }

  def self.provider_registry
    @provider_registry
  end

  def self.register_provider(symbol, klass)
    @provider_registry[symbol.to_sym] = klass
  end

  def self.unregister_provider(symbol)
    @provider_registry.delete(symbol.to_sym)
  end

  # Configuration entrypoint
  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.config
    configuration
  end
end
