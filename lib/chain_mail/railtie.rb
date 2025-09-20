# frozen_string_literal: true

require "rails"

module ChainMail
  class Railtie < Rails::Railtie
    initializer "chain_mail.add_delivery_method" do
      ActionMailer::Base.add_delivery_method :chain_mail, ChainMail::Delivery
    end
  end
end
