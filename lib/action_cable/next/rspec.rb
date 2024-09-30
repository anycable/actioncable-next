# frozen_string_literal: true

# RSpec patches from https://github.com/palkan/rspec-rails/pull/1

require "rspec/rails/example/channel_example_group"

if defined?(RSpec::Rails::ChannelExampleGroup)
  RSpec::Rails::ChannelExampleGroup.prepend(Module.new do
    def connection_class
      (_connection_class || described_class).then do |klass|
        # Connection class either specified explicitly or is a described class
        next klass if klass && klass <= ::ActionCable::Connection::Base

        # Otherwise, fallback to the default connection class
        tests_connection ::ActionCable.server.config.connection_class.call

        _connection_class
      end
    end
  end)
end

RSpec::Rails::Matchers::ActionCable::HaveStream.prepend(Module.new do
  def match(subscription)
    case subscription
    when ::ActionCable::Channel::Base
      @actual = streams_for(subscription)
      no_expected? ? actual.any? : actual.any? { |i| expected === i }
    else
      raise ArgumentError, "have_stream, have_stream_from and have_stream_from support expectations on subscription only"
    end
  end

  private
    def streams_for(subscription)
      # In Rails 8, subscription.streams returns a real subscriptions hash,
      # not a fake array of stream names like in Rails 6-7.
      # So, we must use #stream_names instead.
      subscription.respond_to?(:stream_names) ? subscription.stream_names : subscription.streams
    end
end)
