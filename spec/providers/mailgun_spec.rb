# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe ChainMail::Providers::Mailgun do
  let(:domain) { "example.com" }
  let(:api_key) { "test-api-key" }
  let(:creds) { { domain: domain, api_key: api_key } }
  let(:mail) do
    instance_double(
      "Mail",
      from: ["sender@example.com"],
      to: ["recipient1@example.com", "recipient2@example.com"],
      subject: "Test Subject",
      body: double(decoded: "<p>Hello World</p>")
    )
  end
  let(:mailgun_url) { "https://api.mailgun.net/v3/#{domain}/messages" }

  before do
    stub_request(:post, mailgun_url)
      .with(
        basic_auth: ["api", api_key],
        body: {
          from: mail.from.first,
          to: mail.to.join(","),
          subject: mail.subject,
          html: mail.body.decoded
        }
      )
      .to_return(
        status: 200,
        body: '{"id":"<2025@mailgun.org>","message":"Queued. Thank you."}',
        headers: { "Content-Type" => "application/json" }
      )
  end

  it "sends correct payload and headers to Mailgun API" do
    response = described_class.deliver(mail, creds)
    expect(WebMock).to have_requested(:post, mailgun_url)
      .with(
        basic_auth: ["api", api_key],
        body: {
          from: mail.from.first,
          to: mail.to.join(","),
          subject: mail.subject,
          html: mail.body.decoded
        }
      ).once
    expect(response[:success]).to eq(true)
    expect(response[:error]).to be_nil
    expect(response[:response]).to be_a(Net::HTTPOK)
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

    before do
      stub_request(:post, mailgun_url)
        .with(
          basic_auth: ["api", api_key],
          body: {
            from: mail.from.first,
            to: mail.to.join(","),
            subject: mail.subject,
            html: mail.body.decoded
          }
        )
        .to_return(
          status: 200,
          body: '{"id":"<2025@mailgun.org>","message":"Queued. Thank you."}',
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "reflects changes in payload" do
      described_class.deliver(mail, creds)
      expect(WebMock).to have_requested(:post, mailgun_url)
        .with(
          basic_auth: ["api", api_key],
          body: {
            from: mail.from.first,
            to: mail.to.join(","),
            subject: mail.subject,
            html: mail.body.decoded
          }
        )
    end
  end

  context "when credentials are missing" do
    it "returns error for missing domain" do
      result = described_class.deliver(mail, { api_key: api_key })
      expect(result[:success]).to eq(false)
      expect(result[:error]).to match(/MAILGUN_DOMAIN/)
    end

    it "returns error for missing api_key" do
      result = described_class.deliver(mail, { domain: domain })
      expect(result[:success]).to eq(false)
      expect(result[:error]).to match(/MAILGUN_API_KEY/)
    end
  end

  context "when Mailgun API returns an error" do
    before do
      stub_request(:post, mailgun_url)
        .with(
          basic_auth: ["api", api_key],
          body: {
            from: mail.from.first,
            to: mail.to.join(","),
            subject: mail.subject,
            html: mail.body.decoded
          }
        )
        .to_return(
          status: 401,
          body: '{"message":"Unauthorized"}',
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "returns error result with API error details" do
      result = described_class.deliver(mail, creds)
      expect(result[:success]).to eq(false)
      expect(result[:error]).to match(/Mailgun API error: 401/)
      expect(result[:response]).to be_a(Net::HTTPUnauthorized)
    end
  end

  context "when an exception occurs during request" do
    before do
      allow(Net::HTTP).to receive(:start).and_raise(StandardError.new("network failure"))
    end

    it "returns error result with exception message" do
      result = described_class.deliver(mail, creds)
      expect(result[:success]).to eq(false)
      expect(result[:error]).to match(/network failure/)
      expect(result[:response]).to be_nil
    end
  end
end
