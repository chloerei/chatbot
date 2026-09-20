class ChatsController < ApplicationController
  layout "chats"

  before_action :set_chat, only: [ :show, :destroy ]

  # Feeds the drawer's :chats_sidebar turbo frame, so it never renders the layout.
  def index
    @chats = Current.user.chats.order(created_at: :desc)

    render layout: false
  end

  def new
    @message = Message.new
  end

  def create
    content = params.dig(:message, :content)
    if content.present?
      @chat = Current.user.chats.create!
      @chat.ask_later(content)
      ChatResponseJob.perform_later(@chat)

      redirect_to @chat
    else
      @message = Message.new
      @message.errors.add(:content, "can't be blank")

      render :new, status: :unprocessable_content
    end
  end

  def show
    @message = Message.new
  end

  # The Chat model broadcasts the removal to the drawer's chat list. Deleting
  # from a chat page returns to a fresh chat, while deleting from the sidebar
  # leaves the page where it is.
  def destroy
    @chat.destroy!

    if params[:source] == "chat"
      redirect_to root_path
    else
      head :no_content
    end
  end

  private

  def set_chat
    @chat = Current.user.chats.find(params[:id])
  end
end
