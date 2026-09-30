class Chat < ApplicationRecord
  acts_as_chat

  # The chat's run state, driving the composer's button: idle between turns,
  # responding while a background response is streaming.
  enum :status, { idle: "idle", responding: "responding" }

  belongs_to :user

  # Keep the drawer's chat list in sync for every subscriber. Chats are listed
  # newest first, so new records are prepended to the "chats" target.
  broadcasts_to ->(chat) { chat.user }, inserts_by: :prepend

  # The composer swaps its send button for a stop button while the chat is
  # responding, and back once it is idle. Redraw it whenever the status flips, so
  # callers only have to change the state.
  after_update_commit :broadcast_composer, if: :saved_change_to_status?

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

  # Pushes the composer's current button to every open page for this chat. The
  # browser has no other way to learn the run started or ended, so the status
  # change broadcasts it here.
  def broadcast_composer
    broadcast_replace_to self,
      target: "composer_actions",
      partial: "messages/composer_actions",
      locals: { chat: self }
  end
end
