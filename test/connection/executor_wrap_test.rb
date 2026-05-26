# frozen_string_literal: true

require "test_helper"
require "stubs/test_server"

class ActionCable::Connection::ExecutorWrapTest < ActionCable::TestCase
  class FakeExecutor
    attr_reader :wrap_calls

    def initialize
      @wrap_calls = []
    end

    def wrap(source: nil)
      @wrap_calls << source
      yield
    end
  end

  class Connection < ActionCable::Connection::Base
    cattr_accessor :test_executor

    around_command do |_, inner|
      test_executor.wrap(source: "application.action_cable", &inner)
    end
  end

  class ChatChannel < ActionCable::Channel::Base
    class << self
      attr_accessor :subscribed_count
    end

    self.subscribed_count = 0

    def subscribed
      self.class.subscribed_count += 1
    end
  end

  setup do
    Connection.test_executor = FakeExecutor.new
    ChatChannel.subscribed_count = 0

    @server = TestServer.new
    @env = Rack::MockRequest.env_for "/test", "HTTP_HOST" => "localhost", "HTTP_CONNECTION" => "upgrade", "HTTP_UPGRADE" => "websocket"

    @socket = ActionCable::Server::Socket.new(@server, @env)
    @connection = Connection.new(@server, @socket)
    @identifier = { channel: "ActionCable::Connection::ExecutorWrapTest::ChatChannel" }.to_json
  end

  attr_reader :server, :env, :connection, :identifier

  test "handle_channel_command runs inside executor.wrap" do
    connection.handle_channel_command({ "identifier" => identifier, "command" => "subscribe" })

    assert_equal ["application.action_cable"], Connection.test_executor.wrap_calls
    assert_equal 1, ChatChannel.subscribed_count
  end
end
