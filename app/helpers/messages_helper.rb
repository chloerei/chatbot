module MessagesHelper
  # Renders a tool call's arguments (its input), dispatching to a per-tool
  # partial when one exists and the shared default otherwise.
  def tool_call_partial(tool_call)
    partial_for(prefix: "messages/tool_calls", name: tool_call.name)
  end

  # Renders a tool call's result (its output). Dispatches on the tool's name so
  # a still-pending call and the broadcast that fills it in pick the same
  # partial.
  def tool_result_partial(tool_call)
    partial_for(prefix: "messages/tool_results", name: tool_call.name)
  end

  # The ids the tool call card and the broadcasts that update it share. Kept in
  # one place on the model so the card, the result replace and the streamed
  # output append cannot drift apart.
  def tool_call_dom_id(tool_call)
    Message.tool_call_dom_id(tool_call.tool_call_id)
  end

  def tool_output_dom_id(tool_call)
    Message.tool_output_dom_id(tool_call.tool_call_id)
  end

  private

  def partial_for(prefix:, name:)
    normalized = name.to_s.underscore.tr("-", "_")
    if normalized.present? && lookup_context.exists?(normalized, [ prefix ], true)
      "#{prefix}/#{normalized}"
    else
      "#{prefix}/default"
    end
  end
end
