# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe ChainMail::Providers::Brevo do
  let(:mail) do
    instance_double(
      "Mail",
      from: ["sender@example.com"],
      to: ["recipient1@example.com", "recipient2@example.com"],
      subject: "Test Subject",
      body: double(decoded: "<p>Hello World</p>")
    )
  end

  let(:creds) { { api_key: "test-api-key" } }
  let(:brevo_url) { "https://api.brevo.com/v3/smtp/email" }
  let(:headers) do
    {
      "api-key" => creds[:api_key],
      "Content-Type" => "application/json"
    }
  end
  let(:payload) do
    {
      sender: { email: mail.from.first },
      to: mail.to.map { |t| { email: t } },
      subject: mail.subject,
      htmlContent: mail.body.decoded
    }
  end

  before do
    stub_request(:post, brevo_url)
      .with(
        headers: headers,
        body: payload.to_json
      )
      .to_return(status: 200, body: '{"message":"success"}', headers: { "Content-Type" => "application/json" })
  end

  it "sends correct payload to Brevo API" do
    described_class.deliver(mail, creds)
    expect(WebMock).to have_requested(:post, brevo_url)
      .with(
        headers: headers,
        body: payload.to_json
      ).once
  end

  context "with different mail attributes" do
    let(:mail) do
      instance_double(
        "Mail",
        from: ["other_sender@example.com"],
        to: ["other_recipient@example.com"],
        subject: "Other Subject",
        body: double(decoded: "<h1>Other Body</h1>")
      )
    end

    let(:payload) do
      {
        sender: { email: mail.from.first },
        to: mail.to.map { |t| { email: t } },
        subject: mail.subject,
        htmlContent: mail.body.decoded
      }
    end

    before do
      stub_request(:post, brevo_url)
        .with(
          headers: headers,
          body: payload.to_json
        )
        .to_return(status: 200, body: '{"message":"success"}', headers: { "Content-Type" => "application/json" })
    end

    it "sends correct payload for different mail object" do
      described_class.deliver(mail, creds)
      expect(WebMock).to have_requested(:post, brevo_url)
        .with(
          headers: headers,
          body: payload.to_json
        ).once
    end
  end
end
