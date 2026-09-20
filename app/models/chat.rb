class Chat < ApplicationRecord
  acts_as_chat

  belongs_to :user

  # Keep the drawer's chat list in sync for every subscriber. Chats are listed
  # newest first, so new records are prepended to the "chats" target.
  broadcasts_to ->(chat) { chat.user }, inserts_by: :prepend

  def title
    messages.first&.content.presence || "Chat ##{id}"
  end
end
