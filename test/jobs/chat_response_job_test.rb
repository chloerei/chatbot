require "test_helper"

class ChatResponseJobTest < ActiveJob::TestCase
  setup do
    @chat = users(:one).chats.create!
    @assistant = @chat.messages.create!(role: "assistant", content: "")
  end

  test "streams reasoning into its own region above the answer" do
    chunks = [
      chunk(thinking: "Six times "),
      chunk(thinking: "seven.", content: "Forty-two")
    ]

    streams = capture_turbo_stream_broadcasts(@chat) do
      with_chunks(chunks) { ChatResponseJob.perform_now(@chat) }
    end

    region = streams.find { |s| s["action"] == "prepend" && s["target"] == "message_#{@assistant.id}" }
    assert region, "expected the reasoning region, got #{targets(streams)}"
    assert_includes region.at("template").inner_html, "Six times seven."

    content = streams.find { |s| s["action"] == "append" && s["target"] == "message_#{@assistant.id}_content" }
    assert_includes content.at("template").inner_html, "Forty-two"
  end

  test "does not settle the reasoning region until the answer starts" do
    streams = capture_turbo_stream_broadcasts(@chat) do
      with_chunks([ chunk(thinking: "Six times seven.") ]) { ChatResponseJob.perform_now(@chat) }
    end

    assert streams.any? { |s| s["action"] == "prepend" && s["target"] == "message_#{@assistant.id}" },
      "expected the reasoning region, got #{targets(streams)}"
    refute streams.any? { |s| s["action"] == "replace" && s["target"] == "message_#{@assistant.id}_thinking" },
      "expected reasoning to stay unsettled until the answer starts"
  end

  test "leaves no reasoning region when the model does not think" do
    streams = capture_turbo_stream_broadcasts(@chat) do
      with_chunks([ chunk(content: "Forty-two") ]) { ChatResponseJob.perform_now(@chat) }
    end

    refute streams.any? { |stream| stream["target"] == "message_#{@assistant.id}" },
      "expected no reasoning region, got #{targets(streams)}"
  end

  private

  def chunk(content: nil, thinking: nil)
    RubyLLM::Message.new(
      role: :assistant,
      content: content,
      thinking: thinking && RubyLLM::Thinking.new(text: thinking)
    )
  end

  def targets(streams)
    streams.map { |stream| [ stream["action"], stream["target"] ] }.inspect
  end

  # Streams +chunks+ through the job without reaching a provider.
  def with_chunks(chunks)
    agent = Object.new
    agent.define_singleton_method(:complete) { |&block| chunks.each(&block) }

    original = ChatAgent.method(:new)
    ChatAgent.define_singleton_method(:new) { |**| agent }
    yield
  ensure
    ChatAgent.define_singleton_method(:new, original)
  end
end
