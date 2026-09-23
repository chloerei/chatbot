class ChatResponseJob < ApplicationJob
  # Chunks arrive far faster than a reader can follow, and every one is a
  # separate write to the cable. Coalesce them and flush at most this often, so
  # the stream paints steadily instead of in a burst per token.
  BROADCAST_INTERVAL = 0.1 # seconds

  def perform(chat)
    @content = +""
    @thinking = +""
    @thinking_inserted = false
    @message = nil
    @flushed_at = clock

    ChatAgent.new(chat: chat).complete do |chunk|
      # The turn can hand off to a new message (a tool result, then the next
      # assistant turn), so flush the pending text before retargeting.
      latest = chat.messages.last
      if latest != @message
        flush
        @message = latest
        @thinking_inserted = false
      end

      append_thinking chunk.thinking
      append_content chunk.content

      flush if clock - @flushed_at >= BROADCAST_INTERVAL
    end

    flush
  end

  private

  def append_thinking(thinking)
    text = thinking&.text
    @thinking << text if text.present?
  end

  def append_content(content)
    @content << content if content.present?
  end

  # Hand whatever has piled up to the message it belongs to. Runs when the
  # interval elapses and once more when the stream ends, so no tail is lost.
  def flush
    return if @thinking.empty? && @content.empty?

    flush_thinking
    flush_content
    @flushed_at = clock
  end

  # Reasoning arrives before the answer and gets a region of its own. The region
  # is created on the first fragment, so a turn that never thinks leaves no
  # empty box behind.
  def flush_thinking
    return if @thinking.empty?

    unless @thinking_inserted
      @message.broadcast_insert_thinking
      @thinking_inserted = true
    end

    @message.broadcast_append_thinking_chunk(@thinking)
    @thinking.clear
  end

  def flush_content
    return if @content.empty?

    @message.broadcast_append_chunk(@content)
    @content.clear
  end

  # Monotonic, so a wall-clock jump mid-stream cannot stall or hurry the throttle.
  def clock
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
