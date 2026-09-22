class MessagesController < ApplicationController
  layout "chats"

  before_action :set_chat

  def create
    content = params.dig(:message, :content)
    if content.present?
      @chat.ask_later(content)
      ChatResponseJob.perform_later(@chat)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @chat }
      end
    else
      @message = @chat.messages.build
      @message.errors.add(:content, "can't be blank")

      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_content }
        # The chat page belongs to ChatsController#show, so hand this back to it
        # rather than rebuilding its paginated message list here.
        format.html { redirect_to @chat, alert: @message.errors.full_messages.to_sentence }
      end
    end
  end

  private

  def set_chat
    @chat = Current.user.chats.find(params[:chat_id])
  end
end
