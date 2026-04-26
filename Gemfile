# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in fsrs.gemspec
gemspec

# Silence ruby deprecation warnings about irb and rdoc gems
# no longer being included in stdlib from Ruby 3.5.0
gem "irb"
gem "rdoc"

gem "rake", "~> 13.0"
gem "rubocop", "~> 1.21"
gem "rubocop-minitest"

group :test do
  gem "minitest", "~> 5.16"
  gem "simplecov", require: false
end
