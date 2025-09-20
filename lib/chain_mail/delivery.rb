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
      return unless results.none? { |r| r[:success] }

      handle_delivery_errors(mail, results)
    end

    private

    def validate_mail!(mail)
      required_fields = %i[to from subject body]
      missing = required_fields.select do |field|
        !mail.respond_to?(field) ||
          (value = mail.send(field)).nil? ||
          (value.respond_to?(:empty?) && value.empty?)
      end
      return if missing.empty?

      raise "Mail object missing or blank: #{missing.join(', ')}"
    end

    def try_providers(mail)
      providers = ChainMail.config.providers
      validate_providers!(providers)

      results = []
      providers.each do |provider|
        results.concat(try_single_provider(mail, provider))
        return results if successful?(results)
      end
      results
    end

    def validate_providers!(providers)
      raise "ChainMail: No providers configured" if providers.nil? || providers.empty?
      return if providers.all? { |p| p.is_a?(Hash) && p.size == 1 }

      raise "ChainMail: Provider config must be a hash with one key-value pair"
    end

    def successful?(results)
      results.any? { |r| r[:success] }
    end

    def try_single_provider(mail, provider)
      name, creds = provider.first
      return invalid_credentials_result(name) unless creds.is_a?(Hash)

      begin
        result = provider_class(name).deliver(mail, creds)
        return success_result(name, result) if result[:success]

        error_result(name, result)
      rescue StandardError => e
        exception_result(name, e)
      end
    end

    def invalid_credentials_result(name)
      [{ provider: name, error: "Credentials must be a hash", response: nil }]
    end

    def success_result(name, result)
      Rails.logger.info("[ChainMail] Email sent via #{name}")
      [{ provider: name, success: true, error: nil, response: result[:response] }]
    end

    def error_result(name, result)
      Rails.logger.error("[ChainMail] Provider #{name} failed: #{result[:error]}")
      [{ provider: name, error: result[:error], response: result[:response] }]
    end

    def exception_result(name, exception)
      Rails.logger.error("[ChainMail] Provider #{name} raised: #{exception.message}")
      [{ provider: name, error: exception.message, response: nil }]
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
