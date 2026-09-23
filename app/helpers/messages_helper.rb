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
