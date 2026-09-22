require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    @chat = @user.chats.create!
  end

  test "create with content persists the message and starts a response" do
    assert_difference -> { messages_count }, 1 do
      post chat_messages_path(@chat), params: { message: { content: "Hi there" } }
    end

    message = messages.last
    assert_equal "user", message.role
    assert_equal "Hi there", message.content

    assert_enqueued_with job: ChatResponseJob, args: [ @chat ]
    assert_redirected_to chat_path(@chat)
  end

  test "create with content responds to turbo_stream" do
    assert_difference -> { messages_count }, 1 do
      post chat_messages_path(@chat), params: { message: { content: "Hi there" } }, as: :turbo_stream
    end

    assert_response :success
    assert_enqueued_with job: ChatResponseJob, args: [ @chat ]
  end

  test "create without content does not start a response" do
    assert_no_difference -> { messages_count } do
      assert_no_enqueued_jobs only: ChatResponseJob do
        post chat_messages_path(@chat), params: { message: { content: "" } }
      end
    end

    assert_redirected_to chat_path(@chat)
  end

  test "create without content responds to turbo_stream" do
    assert_no_difference -> { messages_count } do
      assert_no_enqueued_jobs only: ChatResponseJob do
        post chat_messages_path(@chat), params: { message: { content: "" } }, as: :turbo_stream
      end
    end

    assert_response :unprocessable_content
  end

  test "create does not allow posting to another user's chat" do
    other_chat = users(:two).chats.create!

    assert_no_difference -> { Message.count } do
      assert_no_enqueued_jobs only: ChatResponseJob do
        post chat_messages_path(other_chat), params: { message: { content: "Hi there" } }
      end
    end

    assert_response :not_found
  end

  private
    def messages
      Message.where(chat_id: @chat.id).order(:created_at)
    end

    def messages_count
      messages.count
    end
end
