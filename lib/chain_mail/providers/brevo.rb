# frozen_string_literal: true

module ChainMail
  module Providers
    class Brevo < Base
      def self.deliver(mail, creds)
        payload = {
          sender: { email: mail.from.first },
          to: mail.to.map { |t| { email: t } },
          subject: mail.subject,
          htmlContent: mail.body.decoded
        }
        headers = { "api-key" => creds[:api_key], "Content-Type" => "application/json" }
        post_json("https://api.brevo.com/v3/smtp/email", headers, payload)
      end
    end
  end
end
