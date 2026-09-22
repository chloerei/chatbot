class ChatResponseJob < ApplicationJob
  def perform(chat)
    chat_agent = ChatAgent.new(chat: chat)

    chat_agent.complete do |chunk|
      if chunk.content && !chunk.content.empty?
        message = chat.messages.last
        message.broadcast_append_chunk(chunk.content)
      end
    end
  end
end
