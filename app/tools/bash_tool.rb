require "open3"
require "fileutils"

class BashTool < RubyLLM::Tool
  description "Execute bash commands on the local machine, in the workspace directory."

  parameter :command, type: String, description: "The bash command to execute."

  # Commands run inside storage/workspace so the model has a predictable place
  # to read and write files, isolated from the app's own source.
  WORKSPACE = Rails.root.join("storage", "workspace")

  # The chat streams the command's output into the call's output region as it
  # runs, so the card fills in before the call finishes.
  def initialize(chat:)
    @chat = chat
  end

  def execute(command:, tool_call: nil)
    FileUtils.mkdir_p(WORKSPACE)
    output = +""

    Open3.popen2e(command, chdir: WORKSPACE) do |_stdin, stream, wait_thread|
      stream.each do |chunk|
        output << chunk
        @chat.broadcast_tool_output(tool_call, chunk) if tool_call
      end
      wait_thread.value
    end

    output
  end
end
