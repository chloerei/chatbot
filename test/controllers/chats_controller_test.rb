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
    get new_chat_path

    assert_response :success
  end

  test "create with a prompt starts a chat on the default model" do
    assert_difference -> { Chat.count }, 1 do
      post chats_path, params: { chat: { prompt: "Hello there" } }
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

  test "create without a prompt does not start a chat" do
    assert_no_difference -> { Chat.count } do
      assert_no_enqueued_jobs only: ChatResponseJob do
        post chats_path, params: { chat: { prompt: "" } }
      end
    end

    assert_response :unprocessable_content
  end

  test "show" do
    chat = @user.chats.create!

    get chat_path(chat)

    assert_response :success
  end

  test "destroy" do
    chat = @user.chats.create!

    assert_difference -> { Chat.count }, -1 do
      delete chat_path(chat)
    end

    assert_redirected_to chats_path
  end
end
