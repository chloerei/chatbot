class ChatResponseJob < ApplicationJob
  def perform(chat)
    chat.complete do |chunk|
      if chunk.content && !chunk.content.empty?
        message = chat.messages.last
        message.broadcast_append_chunk(chunk.content)
      end
    end
  end
end
