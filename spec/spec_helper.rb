# frozen_string_literal: true

require "rspec"
require "webmock/rspec"
require "faraday" # Optional, for Faraday stubs if needed

# Block all real HTTP requests except those explicitly stubbed
WebMock.disable_net_connect!(allow_localhost: true)

# Optionally set up Faraday stubs for adapter specs
module FaradaySpecHelper
  def faraday_stub
    Faraday::Adapter::Test::Stubs.new
  end
end

RSpec.configure do |config|
  # Clean, idiomatic RSpec settings
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Include FaradaySpecHelper for adapter specs
  config.include FaradaySpecHelper

  # Load support files if present
  Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each { |f| require f }
end

# Require the gem's main file
require_relative "../lib/chain_mail"
