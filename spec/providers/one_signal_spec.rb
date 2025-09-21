# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe ChainMail::Providers::OneSignal do
  let(:api_key) { "test-onesignal-key" }
  let(:creds) { { api_key: api_key } }
  let(:mail) do
    instance_double(
      "Mail",
      from: ["sender@domain.com"],
      to: ["user1@domain.com", "user2@domain.com"],
      subject: "OneSignal Subject",
      body: double(decoded: "Body content")
    )
  end
  let(:onesignal_url) { "https://onesignal.com/api/v1/notifications" }
  let(:payload) do
    {
      include_email_tokens: mail.to,
      subject: mail.subject,
      body: mail.body.decoded,
      from_email: mail.from.first
    }
  end
  let(:headers) do
    {
      "Authorization" => "Basic #{api_key}",
      "Content-Type" => "application/json"
    }
  end

  before do
    stub_request(:post, onesignal_url)
      .with(
        headers: headers,
        body: payload.to_json
      )
      .to_return(
        status: 200,
        body: '{"id":"notif-id","recipients":2}',
        headers: { "Content-Type" => "application/json" }
      )
  end

  it "sends correct payload and headers to OneSignal API" do
    response = described_class.deliver(mail, creds)
    expect(WebMock).to have_requested(:post, onesignal_url)
      .with(
        headers: headers,
        body: payload.to_json
      ).once
    expect(response[:success]).to eq(true)
    expect(response[:error]).to be_nil
    expect(response[:response]).to be_a(Net::HTTPOK).or be_a(Net::HTTPResponse)
  end

  context "with different mail attributes" do
    let(:mail) do
      instance_double(
        "Mail",
        from: ["other@domain.com"],
        to: ["alt@domain.com"],
        subject: "Alt Subject",
        body: double(decoded: "Alt body")
      )
    end

    it "sends correct payload for alternate mail" do
      described_class.deliver(mail, creds)
      expect(WebMock).to have_requested(:post, onesignal_url)
        .with(
          headers: headers,
          body: {
            include_email_tokens: mail.to,
            subject: mail.subject,
            body: mail.body.decoded,
            from_email: mail.from.first
          }.to_json
        ).once
    end
  end

  context "when credentials are missing" do
    before do
      stub_request(:post, onesignal_url)
        .with(
          headers: {
            "Authorization" => "Basic",
            "Content-Type" => "application/json"
          }
        )
        .to_return(status: 400, body: '{"errors":["Missing API key"]}')
    end

    it "returns error for missing api_key" do
      result = described_class.deliver(mail, {})
      expect(result[:success]).to eq(false)
      expect(result[:error]).to match(/missing/i)
    end
  end

  context "when OneSignal API returns error" do
    before do
      stub_request(:post, onesignal_url)
        .with(headers: headers)
        .to_return(status: 401, body: '{"errors":["Invalid credentials"]}')
    end

    it "returns error for API failure" do
      result = described_class.deliver(mail, creds)
      expect(result[:success]).to eq(false)
      expect(result[:error]).to match(/invalid credentials/i)
    end
  end

  context "when an exception occurs" do
    before do
      stub_request(:post, "https://onesignal.com/api/v1/notifications")
        .to_raise(StandardError.new("Unexpected error"))
    end

    it "returns error for exception" do
      result = described_class.deliver(mail, creds)
      expect(result[:success]).to eq(false)
      expect(result[:error]).to match(/unexpected error/i)
    end
  end
end
