# frozen_string_literal: true

# Load support files
require_relative "support/coverage"
require_relative "support/webmock"
require_relative "support/faraday_helper"

require "rspec"

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
  Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }
end

# Require the gem's main file
require_relative "../lib/chain_mail"
