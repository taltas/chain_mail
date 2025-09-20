# frozen_string_literal: true

module ChainMail
  module Providers
    class Base
      def self.deliver(mail, creds)
        raise NotImplementedError, "Subclasses must implement deliver(mail, creds)"
      end

      # Helper for HTTP requests, error parsing, etc.
      def self.post_json(url, headers, payload)
        uri = URI(url)
        req = Net::HTTP::Post.new(uri, headers)
        req.body = payload.to_json
        begin
          res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
          if res.is_a?(Net::HTTPSuccess)
            { success: true, response: res, error: nil }
          else
            { success: false, response: res, error: "API error: #{res.code} #{res.body}" }
          end
        rescue StandardError => e
          { success: false, response: nil, error: e.message }
        end
      end
    end
  end
end
