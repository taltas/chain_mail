# frozen_string_literal: true

module ChainMail
  class Delivery
    def initialize(values = {})
      # values can include any ActionMailer options like :to, :from, :subject
      @settings = values
    end

    # Called by Rails ActionMailer
    def deliver!(mail)
      validate_mail!(mail)
      results = try_providers(mail)
      if results.none? { |r| r[:success] }
        handle_delivery_errors(mail, results)
      end      
    end

    private

    def validate_mail!(mail)
      required_methods = %i[to from subject body]
      missing = required_methods.reject { |m| mail.respond_to?(m) }
      return if missing.empty?

      raise ArgumentError, "Mail object missing: #{missing.join(', ')}"
    end

    def try_providers(mail)
      results = []
      ChainMail.config.providers.each do |provider|
        results.concat(try_single_provider(mail, provider))
        # Stop trying more providers if one is successful.
        if results.any? { |r| r[:success] }
          return results
        end
      end
      results
    end

    def try_single_provider(mail, provider)
      name, creds = provider.first
      unless creds.is_a?(Hash)
        return [{ provider: name, error: "Credentials must be a hash", response: nil }]
      end

      begin
        result = provider_class(name).deliver(mail, creds)
        if result[:success]
          Rails.logger.info("[ChainMail] Email sent via #{name}")
          [{ provider: name, success: true, error: nil, response: result[:response] }]
        else
          Rails.logger.error("[ChainMail] Provider #{name} failed: #{result[:error]}")
          [{ provider: name, error: result[:error], response: result[:response] }]
        end
      rescue StandardError => e
        Rails.logger.error("[ChainMail] Provider #{name} raised: #{e.message}")
        [{ provider: name, error: e.message, response: nil }]
      end
    end

    def handle_delivery_errors(mail, errors)
      return if errors.empty?

      error_messages = errors.map { |err| "#{err[:provider]}: #{err[:error]}" }.join("; ")
      raise(
        "ChainMail: All email providers failed for #{mail.to.join(', ')}. " \
        "Errors: #{error_messages}"
      )
    end

    # Provider class resolution using ChainMail.provider_registry
    def provider_class(name)
      klass = ChainMail.provider_registry[name.to_sym]
      raise "ChainMail: Unknown provider #{name}" unless klass

      klass
    end
  end
end
