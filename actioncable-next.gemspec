# frozen_string_literal: true

require_relative "lib/actioncable-next"
version = ActionCableNext::VERSION

Gem::Specification.new do |s|
  s.name        = "actioncable-next"
  s.version     = version
  s.summary     = "Next-gen version of Action Cable"
  s.description = "Next-gen version of Action Cable"

  s.required_ruby_version = ">= 3.1.0"

  s.license = "MIT"

  s.author   = ["Pratik Naik", "David Heinemeier Hansson", "Vladimir Dementyev"]
  s.email    = ["pratiknaik@gmail.com", "david@loudthinking.com", "palkan@evilmartians.com"]
  s.homepage = "https://github.com/anycable/action_cable-next"

  s.files        = Dir["CHANGELOG.md", "MIT-LICENSE", "README.md", "lib/**/*"]
  s.require_path = "lib"

  s.metadata = {
    "bug_tracker_uri"   => "https://github.com/anycable/actioncable-next",
    "changelog_uri"     => "https://github.com/anycable/actioncable-next/blob/v#{version}/CHANGELOG.md",
    "source_code_uri"   => "https://github.com/anycable/actioncable-next",
    "rubygems_mfa_required" => "true",
  }

  s.add_dependency "activesupport", ">= 7.0", "<= 8.1"
  s.add_dependency "actionpack", ">= 7.0", "<= 8.1"

  s.add_dependency "nio4r",            "~> 2.0"
  s.add_dependency "websocket-driver", ">= 0.6.1"
  s.add_dependency "zeitwerk",         "~> 2.6"
end
