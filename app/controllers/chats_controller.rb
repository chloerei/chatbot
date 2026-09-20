class ChatsController < ApplicationController
  layout "chats"

  before_action :load_chats
  before_action :set_chat, only: [ :show, :destroy ]

  def index
  end

  def new
    @chat = Chat.new
  end

  def create
    prompt = params.dig(:chat, :prompt)
    if prompt.present?
      @chat = Current.user.chats.create!
      @chat.ask_later(prompt)
      ChatResponseJob.perform_later(@chat)

      redirect_to @chat, notice: "Chat was successfully created."
    else
      @chat = Chat.new
      @chat.errors.add(:prompt, "can't be blank")

      render :new, status: :unprocessable_content
    end
  end

  def show
    @message = Message.new
  end

  def destroy
    @chat.destroy!
    redirect_to chats_path, notice: "Chat was successfully destroyed.", status: :see_other
  end

  private

  def set_chat
    @chat = Current.user.chats.find(params[:id])
  end
end
