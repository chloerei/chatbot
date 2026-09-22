require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  # The page size the app configures in config/initializers/pagy.rb.
  PAGE_SIZE = Pagy::OPTIONS.fetch(:limit)

  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "index" do
    @user.chats.create!

    get chats_path

    assert_response :success
  end

  test "index renders the newest page and links to the page below it" do
    # One chat past the page size, so a page is left below.
    chats = Array.new(PAGE_SIZE + 1) { @user.chats.create! }
    # This page's oldest chat is the cursor for the next one.
    cursor = chats[1]

    get chats_path

    assert_response :success
    # The hooks the pagination controller reads off the list's own id.
    assert_select "#chats[data-controller~=pagination][data-pagination-auto-load-value=true]"
    assert_select "##{dom_id(chats.last)}"
    assert_select "##{dom_id(chats.first)}", count: 0
    assert_select "a[data-pagination-target=nextLink][href=?]", chats_path(before: cursor.id)
  end

  test "index loads the chats older than the given cursor" do
    chats = Array.new(PAGE_SIZE + 2) { @user.chats.create! }
    cursor = chats[2]

    get chats_path(before: cursor.id)

    assert_response :success
    assert_select "##{dom_id(chats[0])}"
    assert_select "##{dom_id(chats[1])}"
    assert_select "##{dom_id(cursor)}", count: 0
    assert_select "##{dom_id(chats.last)}", count: 0
    # The placeholder belongs to the first page only; later pages are spliced in.
    assert_select "li", text: "No chats yet", count: 0
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

  test "show renders the newest page and links to the page above it" do
    chat = @user.chats.create!
    # One message past the page size, so a page is left above.
    messages = Array.new(PAGE_SIZE + 1) { |i| chat.messages.create!(role: "user", content: "message #{i}") }
    # This page's oldest message is the cursor for the next one.
    cursor = messages[1]

    get chat_path(chat)

    assert_response :success
    # The hooks the pagination controller reads off the list's own id.
    assert_select "#messages[data-controller=pagination][data-pagination-auto-load-value=true]"
    assert_select "#message_#{messages.last.id}"
    assert_select "#message_#{messages.first.id}", count: 0
    assert_select "a[data-pagination-target=nextLink][href=?]", chat_path(chat, before: cursor.id)
  end

  test "show loads the messages older than the given cursor" do
    chat = @user.chats.create!
    messages = Array.new(PAGE_SIZE + 2) { |i| chat.messages.create!(role: "user", content: "message #{i}") }
    # This page's oldest message is the cursor for the next one.
    cursor = messages[2]

    get chat_path(chat, before: cursor.id)

    assert_response :success
    assert_select "#message_#{messages[0].id}"
    assert_select "#message_#{messages[1].id}"
    assert_select "#message_#{cursor.id}", count: 0
    assert_select "#message_#{messages.last.id}", count: 0
  end

  test "show renders messages of every role" do
    chat = @user.chats.create!
    user = chat.messages.create!(role: "user", content: "hello")
    assistant = chat.messages.create!(role: "assistant", content: "hi there")
    system = chat.messages.create!(role: "system", content: "be brief")

    get chat_path(chat)

    assert_response :success
    assert_select "#message_#{user.id}"
    assert_select "#message_#{assistant.id}"
    assert_select "#message_#{system.id}"
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
