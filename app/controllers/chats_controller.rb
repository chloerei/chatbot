class ChatsController < ApplicationController
  layout "chats"

  before_action :set_chat, only: [ :show, :destroy ]

  # Feeds the drawer's :chats_sidebar turbo frame, so it never renders the layout.
  def index
    @chats = Current.user.chats.order(created_at: :desc)

    render layout: false
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

  # The Chat model broadcasts the removal to the drawer's chat list, so the
  # response is intentionally empty and leaves the page where it is.
  def destroy
    @chat.destroy!
    head :no_content
  end

  private

  def set_chat
    @chat = Current.user.chats.find(params[:id])
  end
end
