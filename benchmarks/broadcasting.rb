# frozen_string_literal: true

require "bundler/setup"

require "benchmark/ips"
require "action_cable"

ActionCable.server.config.cable = { "adapter" => ENV.fetch("ACTION_CABLE_ADAPTER", "async") }
ActionCable.server.config.logger = ENV["LOG"] == "1" ? Logger.new(STDOUT) : Logger.new(nil)
ActionCable.server.config.fastlane_broadcasts_enabled = true if %w[1 t true].include?(ENV["FASTLANE_BROADCASTS"])
ActionCable.server.config.worker_pool_size = ENV.fetch("WORKER_POOL_SIZE", 4).to_i

# Number of clients
N = ENV.fetch("N", 10).to_i

# Number of messages to broadcast per run
B = ENV.fetch("M", N * 10).to_i

# Benchmark mode
mode = ENV.fetch("MODE", "benchmark")

$stdout.puts "Running #{mode} with N=#{N}, M=#{B}, adapter=#{ActionCable.server.config.cable["adapter"]}, fastlane_broadcasts_enabled=#{ActionCable.server.config.fastlane_broadcasts_enabled}, worker_pool_size=#{ActionCable.server.config.worker_pool_size}"

module ApplicationCable
  class Connection < ActionCable::Connection::Base
  end

  class Channel < ActionCable::Channel::Base
  end
end

class TestChannel < ApplicationCable::Channel
  def subscribed
    stream_from "all"
  end
end

class TestSocket
  attr_reader :server
  delegate :pubsub, :config, :executor, :logger, :worker_pool, to: :server

  def initialize(server, sync_queue: nil)
    @coder = ActiveSupport::JSON
    @sync_queue = sync_queue
    @server = server
    @transmissions = []
  end

  def perform_work(receiver, method, *args)
    worker_pool.async_invoke(receiver, method, *args, connection: self)
  end

  def transmit(cable_message)
    encode(cable_message).then do
      raw_transmit(_1)
    end
  end

  def raw_transmit(msg)
    @transmissions << msg
    @sync_queue&.push(msg)
  end

  def close(...)
  end

  def encode(cable_message)
    @coder.encode cable_message
  end
end

sync_queue = Queue.new
clients = N.times.map do
  ApplicationCable::Connection.new(ActionCable.server, TestSocket.new(ActionCable.server, sync_queue:))
end

# Subscribe all clients to the same channel
subscribe_cmd = { "command" => "subscribe", "identifier" => { "channel" => "TestChannel" }.to_json }
clients.each { _1.handle_channel_command(subscribe_cmd) }

received = 0
clients.size.times do
  raise "Expected to receive #{clients.size} confirmations, got only #{received}" if sync_queue.pop(timeout: 5.0).nil?
  received += 1
end

SMALL_JSON = { "message" => "hello" }.freeze

require "active_support/time_with_zone"
LARGE_JSON = ActiveSupport::TimeZone.all.take(5).to_json.then { JSON.parse(_1) }.freeze

TURBO_STREAM = <<~HTML
<turbo-stream action="append" target="comments-container">
  <template>
    <div class="flex space-x-4 p-4 bg-white rounded-lg shadow-sm border border-gray-200 mb-4" id="comment-123">
      <div class="flex-shrink-0">
        <img class="h-10 w-10 rounded-full object-cover"
             src="https://avatars.githubusercontent.com/u/12345678"
             alt="User avatar">
      </div>
      <div class="flex-grow">
        <div class="flex items-center justify-between mb-2">
          <div>
            <h4 class="text-sm font-medium text-gray-900">Sarah Johnson</h4>
            <p class="text-xs text-gray-500">Posted 2 minutes ago</p>
          </div>
          <div class="flex items-center space-x-2">
            <button class="text-gray-400 hover:text-gray-600">
              <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 20 20">
                <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM16 12a2 2 0 100-4 2 2 0 000 4z" />
              </svg>
            </button>
          </div>
        </div>

        <div class="prose prose-sm text-gray-700">
          <p>This is a really insightful article! I especially appreciated the section about implementing Hotwire in Ruby on Rails applications. The examples were clear and helped me understand the concepts better.</p>
        </div>

        <div class="mt-3 flex items-center space-x-4">
          <button class="flex items-center text-sm text-gray-500 hover:text-gray-700">
            <svg class="h-4 w-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
            </svg>
            <span>12 likes</span>
          </button>

          <button class="flex items-center text-sm text-gray-500 hover:text-gray-700">
            <svg class="h-4 w-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
            <span>Reply</span>
          </button>
        </div>
      </div>
    </div>
  </template>
</turbo-stream>
HTML

HOTWIRE = { "html" => TURBO_STREAM }.freeze

SCENARIOS = {
  "small json" => SMALL_JSON,
  "large json" => LARGE_JSON,
  "turbo stream" => HOTWIRE
}

if mode == "benchmark"
  $stdout.puts "Running benchmarks..."

  Benchmark.ips do |x|
    x.config(warmup: 5, time: 10)

    SCENARIOS.each do |name, payload|
      x.report("#{name} (#{ActiveSupport::NumberHelper.number_to_human_size(payload.to_json.size)})") do
        Thread.new do
          B.times do
            ActionCable.server.broadcast("all", payload)
          end
        end

        (B * N).times { raise "No broadcast message received" unless sync_queue.pop(timeout: 5.0) }
      end
    end
  end
elsif mode == "profile"
  $stdout.puts "Profiling..."

  require "vernier"

  scenario = ENV.fetch("SCENARIO", "small json")
  payload = SCENARIOS.fetch(scenario)
  path = File.join(__dir__, "../tmp/broadcasting_#{[scenario, N, B, ActionCable.server.config.fastlane_broadcasts_enabled ? "fastlane" : nil].compact.join("-").parameterize}.json")

  # warmup
  th = Thread.new do
    10.times do
      ActionCable.server.broadcast("all", payload)
    end
  end

  (10 * N).times { raise "No broadcast message received" unless sync_queue.pop(timeout: 5.0) }

  Vernier.trace(out: path) do
    th = Thread.new do
      B.times do
        ActionCable.server.broadcast("all", payload)
      end
    end

    (B * N).times { raise "No broadcast message received" unless sync_queue.pop(timeout: 5.0) }
    th.join
  end

  $stdout.puts "Profiling done: #{path}"
elsif mode == "smoke"
  ActionCable.server.broadcast("all", { message: "hello" })
  N.times { raise "No broadcast message received" unless sync_queue.pop(timeout: 5.0) }
  puts "All good"
else
  raise "Unknown mode: #{mode}"
end
