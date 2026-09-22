# Names a chat from its opening message, so the drawer and header show a
# human-readable label instead of the "Untitled" fallback.
class ChatTitleJob < ApplicationJob
  # Keeps a verbose model from filling the whole column.
  MAX_LENGTH = 80

  def perform(chat)
    message = chat.messages.where(role: "user").first
    return if message&.content.blank?

    prompt = <<~PROMPT
      Summarise the user's message below as a short title for the conversation.
      Match the language of the message. Aim for about 6 words, or about 30
      characters for languages written without spaces.
      Reply with the title alone, without quotes.

      <message>
      #{message.content}
      </message>
    PROMPT

    response = RubyLLM.chat(model: chat.model_id, provider: chat.provider).ask(prompt)

    title = response.content.to_s.strip
    return if title.blank?

    chat.update!(title: title.truncate(MAX_LENGTH))
    chat.broadcast_replace_to(
      chat,
      target: ActionView::RecordIdentifier.dom_id(chat, :title),
      partial: "chats/title",
      locals: { chat: chat }
    )
  end
end
