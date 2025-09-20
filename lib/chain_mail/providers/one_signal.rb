# frozen_string_literal: true

module ChainMail
  module Providers
    class OneSignal < Base
      def self.deliver(mail, creds)
        payload = {
          include_email_tokens: mail.to,
          subject: mail.subject,
          body: mail.body.decoded,
          from_email: mail.from.first
        }
        headers = {
          "Authorization" => "Basic #{creds[:api_key]}",
          "Content-Type" => "application/json"
        }
        post_json("https://onesignal.com/api/v1/notifications", headers, payload)
      end
    end
  end
end
