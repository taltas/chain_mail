# frozen_string_literal: true

require_relative "lib/chain_mail/version"

Gem::Specification.new do |spec|
  spec.name        = "chain_mail"
  spec.version     = ChainMail::VERSION
  spec.authors     = ["Toray Altas"]
  spec.email       = ["toray.altas@gmail.com"]

  spec.summary     = "Unified transactional email delivery with failover for Ruby/Rails."
  spec.description =
    "ChainMail provides a unified interface for sending transactional emails through " \
    "multiple providers (SendGrid, Postmark, Mailgun, etc.) " \
    "with automatic failover and Rails integration."
  spec.homepage    = "https://github.com/torayaltas/chain_mail"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"]      = spec.homepage
  spec.metadata["source_code_uri"]   = "https://github.com/torayaltas/chain_mail"
  spec.metadata["changelog_uri"]     = "https://github.com/torayaltas/chain_mail/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .github
                                                             appveyor Gemfile])
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Add dependencies here
  spec.add_dependency "aws-sdk-ses", "~> 1.0"
  spec.add_dependency "rails", ">= 6.0"
end
