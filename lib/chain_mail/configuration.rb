# frozen_string_literal: true

module ChainMail
  class Configuration
    attr_accessor :providers

    def initialize
      @providers = [] # e.g., [:onesignal, :brevo, :sendpulse]
    end
  end
end

# DSL for users
module ChainMail
  class << self
    attr_accessor :config

    def configure
      self.config ||= Configuration.new
      yield(config)
    end
  end
end
