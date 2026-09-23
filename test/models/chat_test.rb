require "test_helper"

class ChatTest < ActiveSupport::TestCase
  test "broadcasting tool output appends to the tool call's output region" do
    chat = users(:one).chats.create!
    tool_call = RubyLLM::ToolCall.new(id: "call_1", name: "bash", arguments: {})

    streams = capture_turbo_stream_broadcasts(chat) do
      chat.broadcast_tool_output(tool_call, "line\n")
    end

    stream = streams.sole
    assert_equal "append", stream["action"]
    assert_equal "message_tool_call_call_1_output", stream["target"]
    assert_includes stream.to_html, "line"
  end
end
