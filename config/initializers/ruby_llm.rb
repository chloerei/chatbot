RubyLLM.configure do |config|
  config.default_model = "deepseek-flash"
  config.deepseek_api_key = ENV["DEEPSEEK_API_KEY"]
end
