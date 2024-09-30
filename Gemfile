# frozen_string_literal: true

source "https://rubygems.org"
gemspec

gem "minitest"

# We need a newish Rake since Active Job sets its test tasks' descriptions.
gem "rake", ">= 13"

# Explicitly avoid 1.x that doesn't support Ruby 2.4+
gem "json", ">= 2.0.0", "!=2.7.0"

# Workaround until Ruby ships with cgi version 0.3.6 or higher.
gem "cgi", ">= 0.3.6", require: false

# Workaround until all supported Ruby versions ship with uri version 0.13.1 or higher.
gem "uri", ">= 0.13.1", require: false

group :rubocop do
  gem "rubocop", ">= 1.25.1", require: false
  gem "rubocop-minitest", require: false
  gem "rubocop-packaging", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-md", require: false
end

gem "puma", ">= 5.0.3", require: false

gem "redis", ">= 4.0.1", require: false

gem "redis-namespace"

gem "pg", require: false if ENV["CI"] || ENV["DATABASE_URL"]

gem "websocket-client-simple", github: "matthewd/websocket-client-simple", branch: "close-race", require: false

rails_version = ENV.fetch("RAILS_VERSION", "~> 7.0")

gem "activerecord", rails_version
gem "actionpack", rails_version
gem "activesupport", rails_version

platforms :mri do
  gem "debug", ">= 1.1.0", require: false
end
