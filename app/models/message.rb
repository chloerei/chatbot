class Message < ApplicationRecord
  acts_as_message
  has_many_attached :attachments

  broadcasts_to ->(message) { message.chat }, inserts_by: :append

  def broadcast_append_chunk(content)
    broadcast_append_to chat,
      target: "message_#{id}_content",
      content: ERB::Util.html_escape(content.to_s)
  end
end
