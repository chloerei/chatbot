class Chat < ApplicationRecord
  acts_as_chat

  belongs_to :user

  def title
    messages.first&.content.presence || "Chat ##{id}"
  end
end
