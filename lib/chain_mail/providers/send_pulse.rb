# frozen_string_literal: true

require "net/http"
require "json"
require "base64"
require "chain_mail/helpers/sendpulse_api"

module ChainMail
  module Providers
    class SendPulse < Base
      def self.validate_credentials(creds)
        user_id = creds[:client_id]
        secret = creds[:client_secret]

        if user_id.nil? || user_id.to_s.strip.empty? ||
           secret.nil? || secret.to_s.strip.empty?
          {
            success: false,
            response: nil,
            error: "Missing SendPulse credentials: client_id and client_secret are required"
          }
        else
          { success: true }
        end
      end

      def self.initialize_api(user_id, secret)
        api = SendpulseApi.new(user_id, secret)
        { success: true, api: api }
      rescue StandardError => e
        {
          success: false,
          response: nil,
          error: "Failed to initialize SendPulse API: #{e.message}"
        }
      end

      def self.generate_plain_text(mail)
        mail.text_part&.decoded || mail.body.decoded.gsub(/<[^>]*>/, "")
      end

      def self.build_email_payload(mail)
        {
          email: {
            from: { name: "ChainMail", email: mail.from.first },
            to: mail.to.map { |email| { name: "", email: email } },
            subject: mail.subject,
            htmlbody: mail.body.decoded,
            textbody: generate_plain_text(mail),
            attachments: []
          }
        }
      end

      def self.handle_api_result(result)
        if result[:is_error]
          { success: false, response: nil, error: result[:message] || "SendPulse API error" }
        else
          { success: true, response: result[:data], error: nil }
        end
      end

      def self.deliver(mail, creds)
        # Validate credentials
        validation_result = validate_credentials(creds)
        return validation_result unless validation_result[:success]

        # Initialize API
        user_id = creds[:client_id]
        secret = creds[:client_secret]
        api_result = initialize_api(user_id, secret)
        return api_result unless api_result[:success]

        # Build email payload and send
        email_payload = build_email_payload(mail)
        begin
          result = api_result[:api].smtp_send_mail(email_payload[:email])
          # Handle API result
          handle_api_result(result)
        rescue StandardError => e
          {
            success: false,
            response: nil,
            error: e.message
          }
        end
      end
    end
  end
end
