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

    it "does not call subsequent providers after a successful delivery" do
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

      expect(provider1_double).to receive(:deliver).with(mail, { api_key: "key1" })
                                                   .and_return({ success: true, error: nil,
                                                                 response: "ok" })
      expect(provider2_double).not_to receive(:deliver)

      ChainMail::Delivery.new.deliver!(mail)
    end

    it "does not call subsequent providers after a successful delivery" do
      provider1_double = class_double("Provider1")
      provider2_double = class_double("Provider2")
      provider3_double = class_double("Provider`3")
      ChainMail.config.providers = [
        { "provider1" => { api_key: "key1" } },
        { "provider2" => { api_key: "key2" } },
        { "provider3" => { api_key: "key3" } }
      ]
      allow(ChainMail).to receive(:provider_registry).and_return({
                                                                   provider1: provider1_double,
                                                                   provider2: provider2_double,
                                                                   provider3: provider3_double
                                                                 })

      expect(provider1_double).to receive(:deliver).with(mail, { api_key: "key1" })
                                                   .and_raise(
                                                     StandardError.new("fail")
                                                   )

      # expect(provider2_double).not_to receive(:deliver)
      expect(provider2_double).to receive(:deliver).with(mail, { api_key: "key2" })
                                                   .and_return({ success: true, error: nil,
                                                                 response: "ok" })
      expect(provider3_double).not_to receive(:deliver)

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

    it "logs an error when all providers fail" do
      provider1_double = class_double("Provider1")
      ChainMail.config.providers = [
        { "provider1" => { api_key: "key1" } }
      ]
      allow(ChainMail).to receive(:provider_registry).and_return({ provider1: provider1_double })
      expect(provider1_double).to receive(:deliver).with(mail, { api_key: "key1" })
                                                   .and_raise(StandardError.new("fail"))
      logger = double("Logger")
      allow(Rails).to receive(:logger).and_return(logger)
      expect(logger).to receive(:error).with(/fail/)
      expect do
        ChainMail::Delivery.new.deliver!(mail)
      end.to raise_error(RuntimeError)
    end

    it "logs a success when a provider delivers" do
      provider1_double = class_double("Provider1")
      ChainMail.config.providers = [
        { "provider1" => { api_key: "key1" } }
      ]
      allow(ChainMail).to receive(:provider_registry).and_return({ provider1: provider1_double })
      expect(provider1_double).to receive(:deliver).with(mail, { api_key: "key1" })
                                                   .and_return({ success: true, error: nil,
                                                                 response: "ok" })
      logger = double("Logger")
      allow(Rails).to receive(:logger).and_return(logger)
      expect(logger).to receive(:info).with("[ChainMail] Email sent via provider1")
      ChainMail::Delivery.new.deliver!(mail)
    end

    it "raises if providers config is empty" do
      ChainMail.config.providers = []
      expect do
        ChainMail::Delivery.new.deliver!(mail)
      end.to raise_error(RuntimeError)
    end

    it "raises if providers config is invalid" do
      ChainMail.config.providers = [{}]
      expect do
        ChainMail::Delivery.new.deliver!(mail)
      end.to raise_error(RuntimeError)
    end

    it "raises if mail is missing required fields" do
      bad_mail = instance_double("Mail", to: nil, from: nil, subject: nil, body: nil)
      provider1_double = class_double("Provider1")
      ChainMail.config.providers = [
        { "provider1" => { api_key: "key1" } }
      ]
      allow(ChainMail).to receive(:provider_registry).and_return({ provider1: provider1_double })
      expect(provider1_double).not_to receive(:deliver)
      expect do
        ChainMail::Delivery.new.deliver!(bad_mail)
      end.to raise_error(RuntimeError)
    end

    include_examples "provider failover", 1
    include_examples "provider failover", 5
    include_examples "provider failover", 10
  end
end
