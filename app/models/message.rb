class Message < ApplicationRecord
  acts_as_message
  has_many_attached :attachments

  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated
  after_destroy_commit -> { broadcast_remove_to chat }

  # Tool results are plumbing, not conversation: they render inside the tool
  # call they answer, so they are left out when messages are listed.
  scope :conversation, -> { where.not(role: "tool") }

  # A message carries its tool calls inside it, so the role alone picks the
  # template: the assistant one draws the cards itself. Overrides the gem, which
  # sends tool calls to a template of their own.
  def to_partial_path
    "messages/#{role.to_s.presence || "assistant"}"
  end

  # The tool call card renders one block per call. The card, the result replace
  # and the streamed output append all target these ids, so they live here.
  def self.tool_call_dom_id(tool_call_id)
    "message_tool_call_#{tool_call_id}"
  end

  def self.tool_output_dom_id(tool_call_id)
    "#{tool_call_dom_id(tool_call_id)}_output"
  end

  def broadcast_append_chunk(content)
    broadcast_append_to chat,
      target: "message_#{id}_content",
      content: ERB::Util.html_escape(content.to_s)
  end

  # Tool results are plumbing, not conversation: they render inside the tool
  # call they answer, never as a message of their own.
  def tool_message?
    role.to_s == "tool"
  end

  private

  # A plain message is appended to the conversation. A tool result is not a
  # message of its own: it fills in the output half of the tool call it answers,
  # so that region is replaced instead.
  def broadcast_created
    if tool_message?
      broadcast_tool_result
    else
      # Synchronous, so the element exists before the update that replaces it is
      # broadcast; otherwise the two jobs can race and the replace targets
      # nothing.
      broadcast_append_to chat, target: "messages"
    end
  end

  def broadcast_updated
    if tool_message?
      broadcast_tool_result
    else
      # Synchronous, so the replacement lands before any later update broadcasts
      # against it.
      broadcast_replace_to chat
    end
  end

  def broadcast_tool_result
    # The message is appended as a blank assistant placeholder before it turns
    # out to be a tool result, so drop that bubble.
    broadcast_remove_to chat, target: "message_#{id}"

    # Re-read the call: the association was cached as nil when the placeholder
    # was created, before the call linked back to this message.
    association(:ruby_llm_parent_tool_call).reset
    call = ruby_llm_parent_tool_call
    return unless call

    broadcast_replace_to chat,
      target: self.class.tool_output_dom_id(call.tool_call_id),
      partial: "messages/tool_call_output",
      locals: { tool_call: call }
  end
end
