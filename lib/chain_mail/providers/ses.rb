# frozen_string_literal: true

require "aws-sdk-ses"

module ChainMail
  module Providers
    class SES < Base
      def self.deliver(mail, creds)
        client = Aws::SES::Client.new(
          region: creds[:region],
          access_key_id: creds[:access_key_id],
          secret_access_key: creds[:secret_access_key]
        )
        client.send_email({
                            destination: { to_addresses: mail.to },
                            message: {
                              body: { html: { charset: "UTF-8", data: mail.body.decoded } },
                              subject: { charset: "UTF-8", data: mail.subject }
                            },
                            source: mail.from.first
                          })
      end
    end
  end
end
