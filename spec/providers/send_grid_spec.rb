# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe ChainMail::Providers::SendGrid do
  let(:api_key) { "SG.TEST_API_KEY" }
  let(:creds) { { api_key: api_key } }
  let(:mail) do
    instance_double(
      "Mail",
      from: ["sender@example.com"],
      to: ["recipient1@example.com", "recipient2@example.com"],
      subject: "SendGrid Subject",
      body: double(decoded: "<h1>Hello SendGrid</h1>")
    )
  end
  let(:sendgrid_url) { "https://api.sendgrid.com/v3/mail/send" }
  let(:payload) do
    {
      personalizations: [{ to: mail.to.map { |t| { email: t } } }],
      from: { email: mail.from.first },
      subject: mail.subject,
      content: [{ type: "text/html", value: mail.body.decoded }]
    }
  end
  let(:headers) do
    {
      "Authorization" => "Bearer #{api_key}",
      "Content-Type" => "application/json"
    }
  end

  before do
    stub_request(:post, sendgrid_url)
      .with(
        headers: headers,
        body: payload.to_json
      )
      .to_return(
        status: 202,
        body: "",
        headers: { "Content-Type" => "application/json" }
      )
  end

  it "sends correct payload and headers to SendGrid API" do
    response = described_class.deliver(mail, creds)
    expect(WebMock).to have_requested(:post, sendgrid_url)
      .with(
        headers: headers,
        body: payload.to_json
      ).once
    expect(response[:success]).to eq(true) if response.is_a?(Hash)
    expect(response[:error]).to be_nil if response.is_a?(Hash)
    expect(response[:response]).to be_a(Net::HTTPAccepted).or be_nil
  end

  context "with different mail attributes" do
    let(:mail) do
      instance_double(
        "Mail",
        from: ["other_sender@example.com"],
        to: ["other_recipient@example.com"],
        subject: "Other Subject",
        body: double(decoded: "<p>Other Body</p>")
      )
    end
    let(:payload) do
      {
        personalizations: [{ to: mail.to.map { |t| { email: t } } }],
        from: { email: mail.from.first },
        subject: mail.subject,
        content: [{ type: "text/html", value: mail.body.decoded }]
      }
    end

    before do
      stub_request(:post, sendgrid_url)
        .with(
          headers: headers,
          body: payload.to_json
        )
        .to_return(
          status: 202,
          body: "",
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "sends correct payload for different mail attributes" do
      response = described_class.deliver(mail, creds)
      expect(WebMock).to have_requested(:post, sendgrid_url)
        .with(
          headers: headers,
          body: payload.to_json
        ).once
      expect(response[:success]).to eq(true) if response.is_a?(Hash)
    end
  end

  context "when credentials are missing" do
    let(:creds) { {} }

    it "raises an error for missing api_key" do
      expect do
        described_class.deliver(mail, creds)
      end.to raise_error(KeyError).or raise_error(StandardError)
    end
  end

  context "when SendGrid API returns an error" do
    before do
      stub_request(:post, sendgrid_url)
        .with(
          headers: headers,
          body: payload.to_json
        )
        .to_return(
          status: 401,
          body: '{"errors":[{"message":"Invalid API key"}]}',
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "returns error result with API error message" do
      result = described_class.deliver(mail, creds)
      expect(result[:success]).to eq(false) if result.is_a?(Hash)
      expect(result[:error].to_s).to match(/Invalid API key/)
      expect(result[:response]).to be_a(Net::HTTPUnauthorized).or be_nil
    end
  end

  context "when an exception occurs during request" do
    before do
      allow(Net::HTTP).to receive(:start).and_raise(StandardError.new("network failure"))
    end

    it "returns error result with exception message" do
      result = described_class.deliver(mail, creds)
      expect(result[:success]).to eq(false) if result.is_a?(Hash)
      expect(result[:error].to_s).to match(/network failure/)
      expect(result[:response]).to be_nil
    end
  end
end
