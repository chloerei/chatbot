require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "index" do
    @user.chats.create!

    get chats_path

    assert_response :success
  end

  test "new" do
    get root_path

    assert_response :success
  end

  test "create with a message starts a chat on the default model" do
    assert_difference -> { Chat.count }, 1 do
      post chats_path, params: { message: { content: "Hello there" } }
    end

    chat = Chat.order(:created_at).last

    assert_equal @user, chat.user
    assert_equal RubyLLM.config.default_model, chat.model.model_id

    message = chat.messages.last
    assert_equal "user", message.role
    assert_equal "Hello there", message.content

    assert_enqueued_with job: ChatResponseJob, args: [ chat ]
    assert_redirected_to chat_path(chat)
  end

  test "create without a message does not start a chat" do
    assert_no_difference -> { Chat.count } do
      assert_no_enqueued_jobs only: ChatResponseJob do
        post chats_path, params: { message: { content: "" } }
      end
    end

    assert_response :unprocessable_content
  end

  test "show" do
    chat = @user.chats.create!

    get chat_path(chat)

    assert_response :success
  end

  test "show does not expose another user's chat" do
    other_chat = users(:two).chats.create!

    get chat_path(other_chat)

    assert_response :not_found
  end

  test "destroy from a chat page redirects to the new chat page" do
    chat = @user.chats.create!

    assert_difference -> { Chat.count }, -1 do
      delete chat_path(chat), params: { source: "chat" }
    end

    assert_redirected_to root_path
  end

  test "destroy from the sidebar leaves the page in place" do
    chat = @user.chats.create!

    assert_difference -> { Chat.count }, -1 do
      delete chat_path(chat), params: { source: "sidebar" }
    end

    # The removal is broadcast to the drawer's chat list, so the response is empty.
    assert_response :no_content
  end

  test "destroy does not destroy another user's chat" do
    other_chat = users(:two).chats.create!

    assert_no_difference -> { Chat.count } do
      delete chat_path(other_chat)
    end

    assert_response :not_found
  end
end
