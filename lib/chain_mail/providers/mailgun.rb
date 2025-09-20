# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module ChainMail
  module Providers
    class Mailgun < Base
      def self.deliver(mail, creds)
        domain = creds[:domain]
        api_key = creds[:api_key]

        return error_result("MAILGUN_DOMAIN or MAILGUN_API_KEY not set") unless domain && api_key

        send_mailgun_request(mail, domain, api_key)
      end

      def self.send_mailgun_request(mail, domain, api_key)
        req = build_mailgun_request(mail, domain, api_key)
        perform_mailgun_request(req)
      end

      def self.build_mailgun_request(mail, domain, api_key)
        uri = URI("https://api.mailgun.net/v3/#{domain}/messages")
        req = Net::HTTP::Post.new(uri)
        req.basic_auth("api", api_key)
        req.set_form_data(
          from: mail.from.first,
          to: mail.to.join(","),
          subject: mail.subject,
          html: mail.body.decoded
        )
        req
      end

      def self.perform_mailgun_request(req)
        res = Net::HTTP.start(req.uri.hostname, req.uri.port, use_ssl: true) { |http| http.request(req) }
        return success_result(res) if res.is_a?(Net::HTTPSuccess)

        error_result("Mailgun API error: #{res.code} #{res.body}", res)
      rescue StandardError => e
        error_result(e.message)
      end

      def self.success_result(response)
        { success: true, response: response, error: nil }
      end

      def self.error_result(error, response = nil)
        { success: false, response: response, error: error }
      end
    end
  end
end
