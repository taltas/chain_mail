# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe ChainMail::Providers::Postmark do
  let(:api_url) { "https://api.postmarkapp.com/email" }
  let(:api_key) { "test-api-key" }
  let(:creds)   { { api_key: api_key } }

  let(:mail) do
    instance_double(
      "Mail",
      from: ["sender@example.com"],
      to: ["recipient1@example.com", "recipient2@example.com"],
      subject: "Test Subject",
      body: double(decoded: "<h1>Hello World</h1>")
    )
  end

  let(:expected_payload) do
    {
      From: "sender@example.com",
      To: "recipient1@example.com,recipient2@example.com",
      Subject: "Test Subject",
      HtmlBody: "<h1>Hello World</h1>"
    }
  end

  let(:expected_headers) do
    {
      "X-Postmark-Server-Token" => api_key,
      "Content-Type" => "application/json"
    }
  end

  before do
    stub_request(:post, api_url)
      .with(
        body: expected_payload.to_json,
        headers: expected_headers
      )
      .to_return(
        status: 200,
        body: '{"MessageID":123}',
        headers: { "Content-Type" => "application/json" }
      )
  end

  describe ".deliver" do
    it "sends the correct payload and headers to Postmark" do
      response = described_class.deliver(mail, creds)
      expect(WebMock).to have_requested(:post, api_url)
        .with(body: expected_payload.to_json, headers: expected_headers)
        .once
      expect(response[:success]).to eq(true)
      expect(response[:error]).to be_nil
      expect(response[:response]).to be_a(Net::HTTPOK)
    end

    it "uses mail object attributes for payload" do
      described_class.deliver(mail, creds)
      expect(WebMock).to(have_requested(:post, api_url)
        .with do |req|
          json = JSON.parse(req.body)
          expect(json["From"]).to eq(mail.from.first)
          expect(json["To"]).to eq(mail.to.join(","))
          expect(json["Subject"]).to eq(mail.subject)
          expect(json["HtmlBody"]).to eq(mail.body.decoded)
        end)
    end

    context "with different mail attributes" do
      let(:mail) do
        instance_double(
          "Mail",
          from: ["other@example.com"],
          to: ["user@example.com"],
          subject: "Another Subject",
          body: double(decoded: "<p>Body</p>")
        )
      end

      let(:expected_payload) do
        {
          From: "other@example.com",
          To: "user@example.com",
          Subject: "Another Subject",
          HtmlBody: "<p>Body</p>"
        }
      end

      it "reflects changes in payload" do
        described_class.deliver(mail, creds)
        expect(WebMock).to have_requested(:post, api_url)
          .with(body: expected_payload.to_json)
      end
    end
  end
end
