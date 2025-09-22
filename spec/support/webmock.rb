# frozen_string_literal: true

require "webmock/rspec"

# Block all real HTTP requests except those explicitly stubbed
WebMock.disable_net_connect!(allow_localhost: true)
