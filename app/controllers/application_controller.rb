class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  # Populates the chats list rendered in the chats layout's drawer.
  def load_chats
    @chats = Current.user.chats.order(created_at: :desc)
  end
end
