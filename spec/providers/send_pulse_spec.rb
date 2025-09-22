# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe ChainMail::Providers::SendPulse do
  let(:client_id) { "test-client-id" }
  let(:client_secret) { "test-client-secret" }
  let(:creds) { { client_id: client_id, client_secret: client_secret } }

  let(:mail) do
    instance_double(
      "Mail",
      from: ["sender@example.com"],
      to: ["recipient1@example.com", "recipient2@example.com"],
      subject: "Test Subject",
      body: double(decoded: "<p>Hello World</p>"),
      text_part: nil
    )
  end

  let(:mock_api) { instance_double("SendpulseApi") }
  let(:smtp_send_mail_result) do
    {
      is_error: false,
      data: { "id" => "smtp-12345", "status" => "success" }
    }
  end

  before do
    allow(SendpulseApi).to receive(:new).and_return(mock_api)
    allow(mock_api).to receive(:smtp_send_mail).and_return(smtp_send_mail_result)
  end

  it "sends correct email payload to SendPulse API" do
    response = described_class.deliver(mail, creds)

    expect(SendpulseApi).to have_received(:new).with(client_id, client_secret)
    expect(mock_api).to have_received(:smtp_send_mail).with(
      from: { name: "ChainMail", email: mail.from.first },
      to: mail.to.map { |email| { name: "", email: email } },
      subject: mail.subject,
      htmlbody: mail.body.decoded,
      textbody: "Hello World",
      attachments: []
    )
    expect(response[:success]).to eq(true)
    expect(response[:error]).to be_nil
    expect(response[:response]).to eq(smtp_send_mail_result[:data])
  end

  context "with different mail attributes" do
    let(:mail) do
      instance_double(
        "Mail",
        from: ["other_sender@example.com"],
        to: ["other_recipient@example.com"],
        subject: "Other Subject",
        body: double(decoded: "<h1>Other Body</h1>"),
        text_part: nil
      )
    end

    it "reflects changes in payload" do
      described_class.deliver(mail, creds)

      expect(mock_api).to have_received(:smtp_send_mail).with(
        from: { name: "ChainMail", email: mail.from.first },
        to: mail.to.map { |email| { name: "", email: email } },
        subject: mail.subject,
        htmlbody: mail.body.decoded,
        textbody: "Other Body",
        attachments: []
      )
    end
  end

  context "with multiple recipients" do
    let(:mail) do
      instance_double(
        "Mail",
        from: ["sender@example.com"],
        to: ["recipient1@example.com", "recipient2@example.com", "recipient3@example.com"],
        subject: "Multiple Recipients",
        body: double(decoded: "<p>Multiple recipients test</p>"),
        text_part: nil
      )
    end

    it "handles multiple recipients correctly" do
      described_class.deliver(mail, creds)

      expected_payload = {
        from: { name: "ChainMail", email: mail.from.first },
        to: mail.to.map { |email| { name: "", email: email } },
        subject: mail.subject,
        htmlbody: mail.body.decoded,
        textbody: "Multiple recipients test",
        attachments: []
      }

      expect(mock_api).to have_received(:smtp_send_mail).with(expected_payload)
    end
  end

  context "when mail has text_part" do
    let(:mail) do
      instance_double(
        "Mail",
        from: ["sender@example.com"],
        to: ["recipient@example.com"],
        subject: "With Text Part",
        body: double(decoded: "<p>HTML Content</p>"),
        text_part: double(decoded: "Plain text content")
      )
    end

    it "uses text_part for textbody when available" do
      described_class.deliver(mail, creds)

      expect(mock_api).to have_received(:smtp_send_mail).with(
        hash_including(
          htmlbody: mail.body.decoded,
          textbody: "Plain text content"
        )
      )
    end
  end

  context "when credentials are missing" do
    context "missing client_id" do
      let(:creds) { { client_secret: client_secret } }

      it "returns error for missing client_id" do
        result = described_class.deliver(mail, creds)
        expect(result[:success]).to eq(false)
        expect(result[:error]).to match(/Missing SendPulse credentials.*client_id/)
        expect(result[:response]).to be_nil
      end
    end

    context "missing client_secret" do
      let(:creds) { { client_id: client_id } }

      it "returns error for missing client_secret" do
        result = described_class.deliver(mail, creds)
        expect(result[:success]).to eq(false)
        expect(result[:error]).to match(/Missing SendPulse credentials.*client_secret/)
        expect(result[:response]).to be_nil
      end
    end

    context "empty credentials" do
      let(:creds) { {} }

      it "returns error for empty credentials" do
        result = described_class.deliver(mail, creds)
        expect(result[:success]).to eq(false)
        expect(result[:error]).to match(/Missing SendPulse credentials.*client_id.*client_secret/)
        expect(result[:response]).to be_nil
      end
    end

    context "nil values" do
      let(:creds) { { client_id: nil, client_secret: nil } }

      it "returns error for nil values" do
        result = described_class.deliver(mail, creds)
        expect(result[:success]).to eq(false)
        expect(result[:error]).to match(/Missing SendPulse credentials.*client_id.*client_secret/)
        expect(result[:response]).to be_nil
      end
    end
  end

  context "when API initialization fails" do
    before do
      allow(SendpulseApi).to receive(:new).and_raise(StandardError.new("API initialization failed"))
    end

    it "returns error result with initialization failure" do
      result = described_class.deliver(mail, creds)
      expect(result[:success]).to eq(false)
      expect(result[:error]).to match(
        /Failed to initialize SendPulse API: API initialization failed/
      )
      expect(result[:response]).to be_nil
    end
  end

  context "when SendPulse API returns an error" do
    let(:smtp_send_mail_result) do
      {
        is_error: true,
        message: "Invalid email address"
      }
    end

    it "returns error result with API error details" do
      result = described_class.deliver(mail, creds)
      expect(result[:success]).to eq(false)
      expect(result[:error]).to match(/Invalid email address/)
      expect(result[:response]).to be_nil
    end
  end

  context "when an exception occurs during request" do
    before do
      allow(mock_api).to receive(:smtp_send_mail).and_raise(StandardError.new("network failure"))
    end

    it "returns error result with exception message" do
      result = described_class.deliver(mail, creds)
      expect(result[:success]).to eq(false)
      expect(result[:error]).to match(/network failure/)
      expect(result[:response]).to be_nil
    end
  end

  context "plain text generation" do
    it "strips HTML tags when no text_part is available" do
      html_content = "<p>Hello <strong>World</strong></p><br/><a href='#'>Link</a>"
      mail_with_html = instance_double("Mail", text_part: nil, body: double(decoded: html_content))
      result = described_class.generate_plain_text(mail_with_html)
      expect(result).to eq("Hello WorldLink")
    end

    it "uses text_part when available" do
      mail_with_text_part = instance_double("Mail",
                                            text_part: double(decoded: "Plain text version"),
                                            body: double(decoded: "<p>HTML version</p>"))
      result = described_class.generate_plain_text(mail_with_text_part)
      expect(result).to eq("Plain text version")
    end
  end

  context "email payload construction" do
    it "builds correct payload structure" do
      payload = described_class.build_email_payload(mail)

      expected_payload = {
        email: {
          from: { name: "ChainMail", email: mail.from.first },
          to: mail.to.map { |email| { name: "", email: email } },
          subject: mail.subject,
          htmlbody: mail.body.decoded,
          textbody: "Hello World",
          attachments: []
        }
      }

      expect(payload).to eq(expected_payload)
    end
  end

  context "API result handling" do
    it "handles successful API result" do
      success_result = { is_error: false, data: { id: "test-123" } }
      handled_result = described_class.handle_api_result(success_result)

      expect(handled_result[:success]).to eq(true)
      expect(handled_result[:response]).to eq({ id: "test-123" })
      expect(handled_result[:error]).to be_nil
    end

    it "handles error API result" do
      error_result = { is_error: true, message: "API Error occurred" }
      handled_result = described_class.handle_api_result(error_result)

      expect(handled_result[:success]).to eq(false)
      expect(handled_result[:response]).to be_nil
      expect(handled_result[:error]).to eq("API Error occurred")
    end

    it "handles error API result without message" do
      error_result = { is_error: true }
      handled_result = described_class.handle_api_result(error_result)

      expect(handled_result[:success]).to eq(false)
      expect(handled_result[:error]).to eq("SendPulse API error")
    end
  end

  context "with complex HTML content" do
    let(:mail) do
      instance_double(
        "Mail",
        from: ["sender@example.com"],
        to: ["recipient@example.com"],
        subject: "Complex HTML",
        body: double(decoded: "<div><h1>Title</h1><p>Paragraph with " \
                              "<em>emphasis</em> and <strong>bold</strong> " \
                              "text.</p><ul><li>Item 1</li><li>Item 2</li>" \
                              "</ul></div>"),
        text_part: nil
      )
    end

    it "correctly strips HTML tags for plain text" do
      described_class.deliver(mail, creds)

      expect(mock_api).to have_received(:smtp_send_mail).with(
        hash_including(
          htmlbody: mail.body.decoded,
          textbody: "TitleParagraph with emphasis and bold text.Item 1Item 2"
        )
      )
    end
  end
end
