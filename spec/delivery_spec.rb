# frozen_string_literal: true

require "rails"
require "active_support/logger"
require "spec_helper"

# Stub Rails.logger to a test logger before running tests
Rails.logger = ActiveSupport::Logger.new(nil)

RSpec.describe ChainMail::Delivery do
  let(:mail) do
    instance_double(
      "Mail",
      to: ["recipient@example.com"],
      from: "sender@example.com",
      subject: "Test Subject",
      body: "Test Body"
    )
  end

  before do
    # Reset providers before each test
    ChainMail.config.providers = []
  end

  describe ".deliver" do
    it "calls the first available provider" do
      provider1_double = class_double("Provider1")
      ChainMail.config.providers = [
        { "provider1" => { api_key: "key1" } }
      ]
      allow(ChainMail).to receive(:provider_registry).and_return({
                                                                   provider1: provider1_double
                                                                 })

      expect(provider1_double).to receive(:deliver).with(mail, { api_key: "key1" })
                                                   .and_return({ success: true, error: nil,
                                                                 response: "ok" })

      ChainMail::Delivery.new.deliver!(mail)
    end

    it "fails over to the next provider if the first raises an error" do
      provider1_double = class_double("Provider1")
      provider2_double = class_double("Provider2")
      ChainMail.config.providers = [
        { "provider1" => { api_key: "key1" } },
        { "provider2" => { api_key: "key2" } }
      ]
      allow(ChainMail).to receive(:provider_registry).and_return({
                                                                   provider1: provider1_double,
                                                                   provider2: provider2_double
                                                                 })

      expect(provider1_double).to receive(:deliver).with(mail,
                                                         { api_key: "key1" })
                                                   .and_raise(
                                                     StandardError.new("fail")
                                                   )
      expect(provider2_double).to receive(:deliver).with(mail, { api_key: "key2" })
                                                   .and_return({ success: true, error: nil,
                                                                 response: "ok" })

      ChainMail::Delivery.new.deliver!(mail)

      # Now simulate failover and expect provider2_double to receive deliver
      # allow(provider1_double).to receive(:deliver)
      #   .with(mail, { api_key: "key1" })
      #   .and_raise(StandardError.new("fail"))
      # expect(provider2_double).to receive(:deliver)
      #   .and_return({ success: true, error: nil, response: "ok" })

      # ChainMail::Delivery.new.deliver!(mail)
    end

    it "raises an error if all providers fail" do
      provider1_double = class_double("Provider1")
      provider2_double = class_double("Provider2")
      ChainMail.config.providers = [
        { "provider1" => { api_key: "key1" } },
        { "provider2" => { api_key: "key2" } }
      ]
      allow(ChainMail).to receive(:provider_registry).and_return({
                                                                   provider1: provider1_double,
                                                                   provider2: provider2_double
                                                                 })

      expect(provider1_double).to receive(:deliver).with(mail,
                                                         { api_key: "key1" })
                                                   .and_raise(
                                                     StandardError.new("fail1")
                                                   )
      expect(provider2_double).to receive(:deliver).with(mail,
                                                         { api_key: "key2" })
                                                   .and_raise(
                                                     StandardError.new("fail2")
                                                   )

      expect do
        ChainMail::Delivery.new.deliver!(mail)
      end.to raise_error(RuntimeError)
    end
  end
end
