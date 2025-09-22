# frozen_string_literal: true

require "simplecov"
require "coveralls"

# Configure SimpleCov with Coveralls formatter
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/config/"
  add_filter "vendor"

  # Generate HTML reports and send to Coveralls
  formatter SimpleCov::Formatter::MultiFormatter.new([
                                                       SimpleCov::Formatter::HTMLFormatter,
                                                       Coveralls::SimpleCov::Formatter
                                                     ])
end
