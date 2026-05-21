# frozen_string_literal: true

require "test_helper"
require "stubs/test_server"
require "active_support/core_ext/hash/indifferent_access"

class BaseTest < ActionCable::TestCase
  def setup
    @server = ActionCable::Server::Base.new
    @server.config.cable = { adapter: "async" }.with_indifferent_access
  end

  class FakeConnection
    def close
    end
  end

  class RaisingConnection
    def close(*)
      raise ClosedQueueError, "queue closed"
    end
  end

  test "#restart closes all open connections" do
    conn = FakeConnection.new
    @server.add_connection(conn)

    assert_called(conn, :close) do
      @server.restart
    end
  end

  test "#restart shuts down worker pool" do
    assert_called(@server.worker_pool, :halt) do
      @server.restart
    end
  end

  test "#restart shuts down pub/sub adapter" do
    assert_called(@server.pubsub, :shutdown) do
      @server.restart
    end
  end

  test "#restart does not propagate exceptions raised by connection#close" do
    @server.add_connection(RaisingConnection.new)

    assert_nothing_raised do
      @server.restart
    end
  end

  test "#restart still closes remaining connections when one #close raises" do
    @server.add_connection(RaisingConnection.new)
    survivor = FakeConnection.new
    @server.add_connection(survivor)

    assert_called(survivor, :close) do
      @server.restart
    end
  end

  test "#restart still shuts down worker pool when connection#close raises" do
    @server.add_connection(RaisingConnection.new)

    assert_called(@server.worker_pool, :halt) do
      @server.restart
    end
  end

  test "#restart still shuts down pub/sub when connection#close raises" do
    @server.add_connection(RaisingConnection.new)

    assert_called(@server.pubsub, :shutdown) do
      @server.restart
    end
  end

  test "#restart is safe to call twice when a connection#close raises" do
    @server.add_connection(RaisingConnection.new)

    @server.restart
    assert_nothing_raised do
      @server.restart
    end
  end

  test "#restart logs an error including the exception class when connection#close raises" do
    @server.add_connection(RaisingConnection.new)

    log = StringIO.new
    old_logger = @server.config.logger
    @server.config.logger = Logger.new(log)

    begin
      @server.restart

      log.rewind
      assert_match(/ClosedQueueError.*queue closed/, log.read)
    ensure
      @server.config.logger = old_logger
    end
  end
end
