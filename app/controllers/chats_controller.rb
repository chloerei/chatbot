class ChatsController < ApplicationController
  layout "chats"

  before_action :set_chat, only: [ :show, :destroy ]

  # Feeds the drawer's :chats_sidebar turbo frame, so it never renders the layout.
  def index
    # Newest first (`reorder`, so the association's ascending default is
    # replaced). Older pages step back from the last chat shown, not from a page
    # number, so a chat created mid-scroll cannot make two pages overlap.
    scope = Current.user.chats.reorder(id: :desc)

    cursor = params[:before].to_s.to_i
    scope = scope.where(id: ...cursor) if cursor.positive?

    # :countless fetches one row past the limit instead of counting a total we
    # never show.
    @pagy, @chats = pagy(:countless, scope)

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

    # Newest first (`reorder`, so the association's ascending default is
    # replaced). Older pages step back from the last message shown, not from a page
    # number, so messages arriving mid-scroll cannot make two pages overlap.
    scope = @chat.messages.reorder(id: :desc)

    cursor = params[:before].to_s.to_i
    scope = scope.where(id: ...cursor) if cursor.positive?

    # :countless fetches one row past the limit instead of counting a total we
    # never show.
    @pagy, messages = pagy(:countless, scope)

    # Oldest first, so the newest message ends up at the bottom.
    @messages = messages.to_a.reverse
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
