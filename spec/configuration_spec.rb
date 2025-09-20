# frozen_string_literal: true

require "spec_helper"

RSpec.describe ChainMail::Configuration do
  before do
    ChainMail.config = nil
  end

  describe ".configure" do
    it "stores provider credentials and order" do
      ChainMail.configure do |config|
        config.providers = [
          { send_grid: { api_key: "SG-KEY" } },
          { mailgun: { domain: "mg.example.com", api_key: "MG-KEY" } }
        ]
      end

      expect(ChainMail.config.providers).to eq([
                                                 { send_grid: { api_key: "SG-KEY" } },
                                                 { mailgun: { domain: "mg.example.com",
                                                              api_key: "MG-KEY" } }
                                               ])
    end
  end

  describe "adapter credential access" do
    let(:mail) do
      double("Mail", to: ["to@example.com"], from: ["from@example.com"], subject: "Subject",
                     body: double(decoded: "<body>"))
    end

    it "passes correct credentials to adapter classes" do
      stub_request(:post, "https://api.sendgrid.com/v3/mail/send")
        .with(headers: { "Authorization" => "Bearer SG-KEY" })
        .to_return(status: 202, body: "", headers: {})

      ChainMail.configure do |config|
        config.providers = [
          { send_grid: { api_key: "SG-KEY" } },
          { mailgun: { domain: "mg.example.com", api_key: "MG-KEY" } }
        ]
      end

      sendgrid_adapter = class_double("ChainMail::Providers::SendGrid").as_stubbed_const
      mailgun_adapter = class_double("ChainMail::Providers::Mailgun").as_stubbed_const

      expect(sendgrid_adapter).to receive(:deliver).with(mail,
                                                         { api_key: "SG-KEY" }).and_return({ success: true })
      expect(mailgun_adapter).to receive(:deliver).with(mail,
                                                        { domain: "mg.example.com",
                                                          api_key: "MG-KEY" }).and_return({ success: true })

      ChainMail.config.providers.each do |provider|
        name, creds = provider.first
        ChainMail::Providers.const_get(name.to_s.split("_").map(&:capitalize).join).deliver(mail,
                                                                                            creds)
      end
    end
  end
end
