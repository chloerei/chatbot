require "open3"

class BashTool < RubyLLM::Tool
  description "Execute bash commands on the local machine."

  parameter :command, type: String, description: "The bash command to execute."

  def execute(command:)
    # Passing a single string lets Ruby route the command through the shell
    # when it contains metacharacters, so pipes, redirects and globs still
    # work.
    output, status = Open3.capture2e(command)

    result = { output: output }
    result[:error] = "Command exited with status #{status.exitstatus}" unless status.success?
    result
  end
end
