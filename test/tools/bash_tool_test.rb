require "test_helper"

class BashToolTest < ActiveSupport::TestCase
  setup do
    @chat = users(:one).chats.create!
    @tool_call = RubyLLM::ToolCall.new(id: "call_1", name: "bash", arguments: {})
  end

  test "streams each chunk to the call's output and returns the combined output" do
    output = nil

    streams = capture_turbo_stream_broadcasts(@chat) do
      output = run_bash("echo a; echo b")
    end

    assert_equal "a\nb\n", output
    assert_equal [ "append", "append" ], streams.map { |stream| stream["action"] }
    assert_equal [ "a\n", "b\n" ], streams.map { |stream| stream.at("template").inner_html }
  end

  test "targets the tool call's output region" do
    streams = capture_turbo_stream_broadcasts(@chat) { run_bash("echo hi") }

    assert_equal "message_tool_call_call_1_output", streams.sole["target"]
  end

  test "merges standard error into the output" do
    assert_equal "oops\n", run_bash("echo oops >&2")
  end

  private

  def run_bash(command)
    BashTool.new(chat: @chat).call(command: command, tool_call: @tool_call)
  end
end
