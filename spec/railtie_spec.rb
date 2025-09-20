# frozen_string_literal: true

require "spec_helper"
require "rails"
require "active_support"
require "active_support/test_case"
require_relative "../lib/chain_mail/railtie"
require "action_mailer"

RSpec.describe ChainMail::Railtie do
  let(:app_class) do
    Class.new(Rails::Application) do
      config.eager_load = false
    end
  end

  it "loads the Railtie" do
    expect(ChainMail::Railtie).to be < Rails::Railtie
  end

  it "runs the initializer" do
    app = app_class.new

    expect(ActionMailer::Base).to receive(:add_delivery_method).with(:chain_mail, ChainMail::Delivery)

    # Simulate Railtie initializer
    ChainMail::Railtie.initializers.each do |init|
      init.run(app)
    end
  end
end
