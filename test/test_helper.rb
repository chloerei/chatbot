ENV["RAILS_ENV"] ||= "test"
# Building a chat reaches the provider-backed RubyLLM chat even when no request
# is made, so a key must be configured. A dummy value keeps the suite offline.
ENV["DEEPSEEK_API_KEY"] ||= "test-key"
require_relative "../config/environment"
require "rails/test_help"
require "turbo/broadcastable/test_helper"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Turbo includes this into ActiveSupport::TestCase only once Action Cable's
    # :action_cable lazy-load hook fires (the first time ActionCable.server is
    # touched), so relying on the auto-include makes tests that use
    # `capture_turbo_stream_broadcasts` depend on which test touches it first.
    # Include it up front so every test can rely on it.
    include Turbo::Broadcastable::TestHelper

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
