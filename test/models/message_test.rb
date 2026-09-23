require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @chat = users(:one).chats.create!
  end

  test "a plain message is appended to the chat's messages" do
    @chat.messages.create!(role: "assistant", content: "Hello")

    append = capture_turbo_stream_broadcasts(@chat).find { |stream| stream["action"] == "append" }

    assert_equal "messages", append["target"]
  end

  test "a tool result replaces the tool call output instead of appending a message" do
    assistant = @chat.messages.create!(role: "assistant", content: "")
    tool_call = assistant.ruby_llm_tool_calls.create!(
      tool_call_id: "call_1", name: "bash", arguments: { "command" => "ls" }
    )
    result = @chat.messages.create!(role: "assistant", content: "")

    tool_call.update!(result: result)
    result.update!(role: "tool", content: "file1\nfile2")

    streams = capture_turbo_stream_broadcasts(@chat)
    actions = streams.map { |stream| [ stream["action"], stream["target"] ] }

    assert_includes actions, [ "remove", "message_#{result.id}" ]
    replacement = streams.find do |stream|
      stream["action"] == "replace" && stream["target"] == "message_tool_call_call_1_output"
    end

    assert replacement, "expected the tool call output to be replaced, got #{actions.inspect}"
    assert_includes replacement.to_html, "file1"
  end

  test "the tool call card renders the call's arguments and its result" do
    assistant = @chat.messages.create!(role: "assistant", content: "")
    tool_call = assistant.ruby_llm_tool_calls.create!(
      tool_call_id: "call_1", name: "bash", arguments: { "command" => "ls" }
    )
    result = @chat.messages.create!(role: "tool", content: "file1\nfile2")
    tool_call.update!(result: result)

    html = ApplicationController.render(partial: "messages/tool_calls", locals: { message: assistant })

    assert_includes html, "message_tool_call_call_1_output"
    assert_includes html, "ls"
    assert_includes html, "file1"
  end

  test "a pending tool call renders its output region without a result" do
    assistant = @chat.messages.create!(role: "assistant", content: "")
    assistant.ruby_llm_tool_calls.create!(tool_call_id: "call_1", name: "bash", arguments: { "command" => "ls" })

    html = ApplicationController.render(partial: "messages/tool_calls", locals: { message: assistant })

    assert_includes html, "message_tool_call_call_1_output"
    assert_includes html, "ls"
  end
end
