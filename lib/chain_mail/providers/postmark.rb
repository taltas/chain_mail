# frozen_string_literal: true

module ChainMail
  module Providers
    class Postmark < Base
      def self.deliver(mail, creds)
        payload = {
          From: mail.from.first,
          To: mail.to.join(","),
          Subject: mail.subject,
          HtmlBody: mail.body.decoded
        }
        headers = {
          "X-Postmark-Server-Token" => creds[:api_key],
          "Content-Type" => "application/json"
        }
        post_json("https://api.postmarkapp.com/email", headers, payload)
      end
    end
  end
end
