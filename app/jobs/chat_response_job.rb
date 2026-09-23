class ChatResponseJob < ApplicationJob
  # Chunks arrive far faster than a reader can follow, and every one is a
  # separate write to the cable. Coalesce them and flush at most this often, so
  # the stream paints steadily instead of in a burst per token.
  BROADCAST_INTERVAL = 0.1 # seconds

  def perform(chat)
    @content = +""
    # Reasoning not yet sent, and the whole of it: the record cannot hand the
    # text back until the turn is saved, so the job keeps its own copy.
    @thinking = +""
    @thinking_all = +""
    @thinking_inserted = false
    @thinking_done = false
    @message = nil
    @flushed_at = clock

    ChatAgent.new(chat: chat).complete do |chunk|
      # The turn can hand off to a new message (a tool result, then the next
      # assistant turn), so flush the pending text before retargeting.
      latest = chat.messages.last
      if latest != @message
        flush
        @message = latest
        @thinking_all = +""
        @thinking_inserted = false
        @thinking_done = false
      end

      append_thinking chunk.thinking
      append_content chunk.content

      # The answer starting means reasoning has ended, so settle the spinner.
      finish_thinking if chunk.content.present?

      flush if clock - @flushed_at >= BROADCAST_INTERVAL
    end

    flush
  end

  private

  def append_thinking(thinking)
    text = thinking&.text
    return if text.blank?

    @thinking << text
    @thinking_all << text
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
  # is created with the first fragment, so a turn that never thinks leaves no
  # empty box behind.
  def flush_thinking
    return if @thinking.empty?

    if @thinking_inserted
      @message.broadcast_append_thinking_chunk(@thinking)
    else
      @message.broadcast_insert_thinking(@thinking)
      @thinking_inserted = true
    end

    @thinking.clear
  end

  # Reasoning ends when the answer begins. Replacing the region settles the
  # spinner into the bulb, and the render carries the whole text, so the pending
  # buffer is dropped rather than appended first. The region may not have reached
  # the DOM yet, in which case it is inserted already settled.
  def finish_thinking
    return if @thinking_done || @thinking_all.empty?

    @thinking_done = true
    @thinking.clear

    if @thinking_inserted
      @message.broadcast_replace_thinking(@thinking_all)
    else
      @message.broadcast_insert_thinking(@thinking_all, streaming: false)
      @thinking_inserted = true
    end
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
