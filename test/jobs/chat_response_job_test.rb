require "test_helper"

class ChatResponseJobTest < ActiveJob::TestCase
  setup do
    @chat = users(:one).chats.create!
    @assistant = @chat.messages.create!(role: "assistant", content: "")
  end

  test "streams reasoning into its own region, inserted before the answer" do
    chunks = [
      chunk(thinking: "Six times "),
      chunk(thinking: "seven.", content: "Forty-two")
    ]

    streams = capture_turbo_stream_broadcasts(@chat) do
      with_chunks(chunks) { ChatResponseJob.perform_now(@chat) }
    end

    insert = streams.find { |stream| stream["action"] == "prepend" && stream["target"] == "message_#{@assistant.id}" }
    assert insert, "expected the reasoning region to be inserted, got #{streams.map { |s| [ s['action'], s['target'] ] }.inspect}"

    thinking = streams.find { |s| s["action"] == "append" && s["target"] == "message_#{@assistant.id}_thinking_content" }
    assert thinking, "expected reasoning to be appended to its region"
    assert_includes thinking.at("template").inner_html, "Six times seven."

    # The region is the append target, so it has to exist first.
    order = streams.map { |stream| [ stream["action"], stream["target"] ] }
    assert_operator order.index([ "prepend", "message_#{@assistant.id}" ]), :<,
      order.index([ "append", "message_#{@assistant.id}_thinking_content" ]),
      "expected the region to be inserted before text is appended into it"

    content = streams.find { |s| s["action"] == "append" && s["target"] == "message_#{@assistant.id}_content" }
    assert_includes content.at("template").inner_html, "Forty-two"
  end

  test "leaves no reasoning region when the model does not think" do
    streams = capture_turbo_stream_broadcasts(@chat) do
      with_chunks([ chunk(content: "Forty-two") ]) { ChatResponseJob.perform_now(@chat) }
    end

    refute streams.any? { |stream| stream["target"] == "message_#{@assistant.id}" },
      "expected no reasoning region, got #{streams.map { |s| [ s['action'], s['target'] ] }.inspect}"
  end

  private

  def chunk(content: nil, thinking: nil)
    RubyLLM::Message.new(
      role: :assistant,
      content: content,
      thinking: thinking && RubyLLM::Thinking.new(text: thinking)
    )
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
