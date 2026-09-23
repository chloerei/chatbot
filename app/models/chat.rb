class Chat < ApplicationRecord
  acts_as_chat

  belongs_to :user

  # Keep the drawer's chat list in sync for every subscriber. Chats are listed
  # newest first, so new records are prepended to the "chats" target.
  broadcasts_to ->(chat) { chat.user }, inserts_by: :prepend

  # Appends a chunk of a running tool's output to its call's output region, so
  # the card fills in as the command produces output. The final result arrives
  # separately as a replace of the same region.
  def broadcast_tool_output(tool_call, content)
    broadcast_append_to self,
      target: Message.tool_output_dom_id(tool_call.id),
      content: ERB::Util.html_escape(content.to_s)
  end

  def display_title
    title.presence || "Untitled"
  end
end
