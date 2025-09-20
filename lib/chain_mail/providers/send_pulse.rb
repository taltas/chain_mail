# frozen_string_literal: true

module ChainMail
  module Providers
    class SendPulse < Base
      TOKEN_CACHE = {}.freeze

      def self.access_token(creds)
        return TOKEN_CACHE[:token] if valid_token?

        response = request_access_token(creds)
        json = parse_access_token_response(response)
        cache_token(json)
        TOKEN_CACHE[:token]
      end

      def self.valid_token?
        TOKEN_CACHE[:expires_at] && Time.now < TOKEN_CACHE[:expires_at]
      end

      def self.request_access_token(creds)
        Net::HTTP.post_form(
          URI("https://api.sendpulse.com/oauth/access_token"),
          grant_type: "client_credentials",
          client_id: creds[:client_id],
          client_secret: creds[:client_secret]
        )
      end

      def self.parse_access_token_response(response)
        JSON.parse(response.body)
      end

      def self.cache_token(json)
        TOKEN_CACHE[:token] = json["access_token"]
        TOKEN_CACHE[:expires_at] = Time.now + json["expires_in"].to_i
      end

      def self.deliver(mail, creds)
        payload = {
          email: {
            from: { email: mail.from.first },
            to: mail.to.map { |t| { email: t } },
            subject: mail.subject,
            html: mail.body.decoded
          }
        }
        headers = {
          "Authorization" => "Bearer #{access_token(creds)}",
          "Content-Type" => "application/json"
        }
        post_json("https://api.sendpulse.com/smtp/emails", headers, payload)
      end
    end
  end
end
