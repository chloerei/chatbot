class ChatResponseJob < ApplicationJob
  # Chunks arrive far faster than a reader can follow, and every one is a
  # separate write to the cable. Coalesce them and flush at most this often, so
  # the stream paints steadily instead of in a burst per token.
  BROADCAST_INTERVAL = 0.1 # seconds

  def perform(chat)
    @buffer = +""
    @message = nil
    @flushed_at = clock

    ChatAgent.new(chat: chat).complete do |chunk|
      next if chunk.content.nil? || chunk.content.empty?

      # The turn can hand off to a new message (a tool result, then the next
      # assistant turn), so flush the pending text before retargeting.
      latest = chat.messages.last
      if latest != @message
        flush
        @message = latest
      end

      @buffer << chunk.content
      flush if clock - @flushed_at >= BROADCAST_INTERVAL
    end

    flush
  end

  private

  # Hand whatever has piled up to the message it belongs to. Runs when the
  # interval elapses and once more when the stream ends, so no tail is lost.
  def flush
    return if @buffer.empty?

    @message.broadcast_append_chunk(@buffer)
    @buffer.clear
    @flushed_at = clock
  end

  # Monotonic, so a wall-clock jump mid-stream cannot stall or hurry the throttle.
  def clock
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
