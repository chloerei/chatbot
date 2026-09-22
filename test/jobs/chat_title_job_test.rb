require "test_helper"

class ChatTitleJobTest < ActiveJob::TestCase
  setup do
    @chat = users(:one).chats.create!
  end

  test "names the chat after the first user message" do
    @chat.messages.create!(role: "assistant", content: "Anything I can help with?")
    @chat.messages.create!(role: "user", content: "How do I deploy a Rails app?")

    with_model_reply("Deploying a Rails app") { ChatTitleJob.perform_now(@chat) }

    assert_equal "Deploying a Rails app", @chat.reload.title
  end

  test "broadcasts a replacement for the chat header title" do
    @chat.messages.create!(role: "user", content: "How do I deploy a Rails app?")

    streams = capture_turbo_stream_broadcasts(@chat) do
      with_model_reply("Deploying a Rails app") { ChatTitleJob.perform_now(@chat) }
    end

    stream = streams.sole
    assert_equal "replace", stream["action"]
    assert_equal ActionView::RecordIdentifier.dom_id(@chat, :title), stream["target"]
    assert_includes stream.at("template").inner_html, "Deploying a Rails app"
  end

  private

  # Replaces RubyLLM.chat with a client whose #ask replies with +content+.
  # With expect_called: false the client raises if the job asks it anything.
  def with_model_reply(content, expect_called: true)
    reply = RubyLLM::Message.new(role: "assistant", content: content)
    client = Object.new
    client.define_singleton_method(:ask) do |_prompt|
      raise "the model should not be called" unless expect_called

      reply
    end

    original = RubyLLM.method(:chat)
    RubyLLM.define_singleton_method(:chat) { |**| client }
    yield
  ensure
    RubyLLM.define_singleton_method(:chat, original)
  end
end
