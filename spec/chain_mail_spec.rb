# frozen_string_literal: true

RSpec.describe ChainMail do
  it "has a version number" do
    expect(ChainMail::VERSION).not_to be nil
  end

  describe ".provider_registry" do
    it "returns the default registry hash" do
      expect(ChainMail.provider_registry).to include(
        brevo: ChainMail::Providers::Brevo,
        send_grid: ChainMail::Providers::SendGrid,
        postmark: ChainMail::Providers::Postmark,
        ses: ChainMail::Providers::SES,
        mailgun: ChainMail::Providers::Mailgun,
        send_pulse: ChainMail::Providers::SendPulse,
        one_signal: ChainMail::Providers::OneSignal
      )
    end
  end

  describe ".register_provider" do
    after { ChainMail.provider_registry.delete(:test_provider) }

    it "adds a new provider to the registry" do
      dummy = Class.new
      ChainMail.register_provider(:test_provider, dummy)
      expect(ChainMail.provider_registry[:test_provider]).to eq(dummy)
    end
  end

  describe ".unregister_provider" do
    before { ChainMail.register_provider(:temp_provider, String) }
    after { ChainMail.provider_registry.delete(:temp_provider) }

    it "removes a provider from the registry" do
      expect(ChainMail.provider_registry).to include(:temp_provider)
      ChainMail.unregister_provider(:temp_provider)
      expect(ChainMail.provider_registry).not_to include(:temp_provider)
    end
  end

  describe ".configure" do
    it "yields the configuration object and allows configuration changes" do
      ChainMail.configure do |config|
        config.providers = %i[onesignal brevo]
      end
      expect(ChainMail.configuration.providers).to eq(%i[onesignal brevo])
    end
  end

  describe ".configuration and .config" do
    it "return the same configuration object" do
      expect(ChainMail.configuration).to be(ChainMail.config)
    end
  end
end
