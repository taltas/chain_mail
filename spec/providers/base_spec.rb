# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe ChainMail::Providers::Base do
  describe ".deliver" do
    it "raises NotImplementedError" do
      expect do
        described_class.deliver(double("Mail"), {})
      end.to raise_error(NotImplementedError, /Subclasses must implement deliver/)
    end
  end

  describe ".post_json" do
    let(:url) { "https://api.example.com/test" }
    let(:headers) { { "Content-Type" => "application/json" } }
    let(:payload) { { foo: "bar" } }

    context "when the HTTP response is successful" do
      before do
        stub_request(:post, url)
          .with(body: payload.to_json, headers: headers)
          .to_return(status: 200,
                     body: '{"result":"ok"}',
                     headers: { "Content-Type" => "application/json" })
      end

      it "returns success: true and response" do
        result = described_class.post_json(url, headers, payload)
        expect(result[:success]).to eq(true)
        expect(result[:response].code).to eq("200")
        expect(result[:error]).to be_nil
      end
    end

    context "when the API returns an error" do
      before do
        stub_request(:post, url)
          .with(body: payload.to_json, headers: headers)
          .to_return(status: 400, body: "Bad Request")
      end

      it "returns success: false and error message" do
        result = described_class.post_json(url, headers, payload)
        expect(result[:success]).to eq(false)
        expect(result[:response].code).to eq("400")
        expect(result[:error]).to match(/API error: 400 Bad Request/)
      end
    end

    context "when an exception occurs" do
      before do
        stub_request(:post, url).to_raise(StandardError.new("network failure"))
      end

      it "returns success: false and exception message" do
        result = described_class.post_json(url, headers, payload)
        expect(result[:success]).to eq(false)
        expect(result[:response]).to be_nil
        expect(result[:error]).to eq("network failure")
      end
    end
  end
end
