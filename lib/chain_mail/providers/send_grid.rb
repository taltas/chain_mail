# frozen_string_literal: true

require "net/http"
require "json"

module ChainMail
  module Providers
    class SendGrid < Base
      def self.deliver(mail, creds)
        if creds[:api_key].nil? || creds[:api_key].to_s.strip.empty?
          raise KeyError,
                "Missing SendGrid API key"
        end

        payload = {
          personalizations: [{ to: mail.to.map { |t| { email: t } } }],
          from: { email: mail.from.first },
          subject: mail.subject,
          content: [{ type: "text/html", value: mail.body.decoded }]
        }
        headers = {
          "Authorization" => "Bearer #{creds[:api_key]}",
          "Content-Type" => "application/json"
        }
        post_json("https://api.sendgrid.com/v3/mail/send", headers, payload)
      end
    end
  end
end
