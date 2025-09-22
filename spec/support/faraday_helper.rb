# frozen_string_literal: true

require "faraday" # Optional, for Faraday stubs if needed

# Optionally set up Faraday stubs for adapter specs
module FaradaySpecHelper
  def faraday_stub
    Faraday::Adapter::Test::Stubs.new
  end
end
