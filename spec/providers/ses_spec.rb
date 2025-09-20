# frozen_string_literal: true

require "spec_helper"
require "aws-sdk-ses"

RSpec.describe ChainMail::Providers::SES do
  let(:mail) do
    instance_double(
      "Mail",
      to: ["recipient@example.com"],
      from: ["sender@example.com"],
      subject: "Test Subject",
      body: double(decoded: "<h1>Hello SES</h1>")
    )
  end

  let(:creds) do
    {
      region: "us-east-1",
      access_key_id: "AKIAFAKEKEY",
      secret_access_key: "FAKESECRET"
    }
  end

  let(:client) { instance_double(Aws::SES::Client) }

  before do
    allow(Aws::SES::Client).to receive(:new).with(
      region: creds[:region],
      access_key_id: creds[:access_key_id],
      secret_access_key: creds[:secret_access_key]
    ).and_return(client)
  end

  it "sends the correct payload to SES" do
    expected_payload = {
      destination: { to_addresses: ["recipient@example.com"] },
      message: {
        body: { html: { charset: "UTF-8", data: "<h1>Hello SES</h1>" } },
        subject: { charset: "UTF-8", data: "Test Subject" }
      },
      source: "sender@example.com"
    }

    expect(client).to receive(:send_email).with(expected_payload)
    described_class.deliver(mail, creds)
  end

  context "with multiple recipients" do
    let(:mail) do
      instance_double(
        "Mail",
        to: ["a@example.com", "b@example.com"],
        from: ["sender@example.com"],
        subject: "Multi",
        body: double(decoded: "Body")
      )
    end

    it "includes all recipients in the payload" do
      expected_payload = {
        destination: { to_addresses: ["a@example.com", "b@example.com"] },
        message: {
          body: { html: { charset: "UTF-8", data: "Body" } },
          subject: { charset: "UTF-8", data: "Multi" }
        },
        source: "sender@example.com"
      }

      expect(client).to receive(:send_email).with(expected_payload)
      described_class.deliver(mail, creds)
    end
  end

  context "when mail.from contains multiple addresses" do
    let(:mail) do
      instance_double(
        "Mail",
        to: ["recipient@example.com"],
        from: ["first@example.com", "second@example.com"],
        subject: "From Multiple",
        body: double(decoded: "Body")
      )
    end

    it "uses the first from address as source" do
      expected_payload = {
        destination: { to_addresses: ["recipient@example.com"] },
        message: {
          body: { html: { charset: "UTF-8", data: "Body" } },
          subject: { charset: "UTF-8", data: "From Multiple" }
        },
        source: "first@example.com"
      }

      expect(client).to receive(:send_email).with(expected_payload)
      described_class.deliver(mail, creds)
    end
  end
end
