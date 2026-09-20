# -*- encoding: utf-8 -*-
# stub: ruby_llm 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby_llm".freeze
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/crmne/ruby_llm/issues", "changelog_uri" => "https://github.com/crmne/ruby_llm/releases", "documentation_uri" => "https://rubyllm.com/", "funding_uri" => "https://github.com/sponsors/crmne", "homepage_uri" => "https://rubyllm.com", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/crmne/ruby_llm" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Carmine Paolino".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-02"
  s.description = "Build AI features the Ruby way. A delightful Ruby AI framework that feels at home in Rails: switch models without rewriting your code, then scale from a single call to production agents, RAG, and workflows. Features chat (text, images, audio, PDFs), image generation, embeddings, tools (function calling), structured output, Rails integration, and streaming. Works with OpenAI, Azure, Anthropic, Google Gemini, Vertex AI, AWS Bedrock, xAI, Cohere, DeepSeek, Mistral, Perplexity, OpenRouter, ElevenLabs, Deepgram, Ollama and GPUStack (local models), and any OpenAI-compatible API. Plain Ruby with a small set of runtime dependencies.".freeze
  s.email = ["carmine@paolino.me".freeze]
  s.executables = ["ruby_llm".freeze]
  s.files = ["exe/ruby_llm".freeze]
  s.homepage = "https://rubyllm.com".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "RubyLLM 2.0.0\n\n  2.0 renames several APIs and changes what message content returns. Coming\n  from 1.x? Read the upgrade guide before you boot:\n\n    https://rubyllm.com/upgrading/\n\n  The Rails upgrade uses forward-only preparation, backfill, and finish\n  phases, with cleanup later. Rename mode is the default; optional copy\n  mode supports a controlled return to 1.16. Read its requirements in the\n  upgrade guide and rehearse on a recent production snapshot.\n\n  Agent skill: https://rubyllm.com/ai-coding-assistants/\n".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.3".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Build AI features the Ruby way: a delightful Ruby AI framework for every major AI provider.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<base64>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<event_stream_parser>.freeze, ["~> 1"])
  s.add_runtime_dependency(%q<faraday>.freeze, [">= 1.10.0"])
  s.add_runtime_dependency(%q<faraday-multipart>.freeze, [">= 1"])
  s.add_runtime_dependency(%q<faraday-net_http>.freeze, [">= 1"])
  s.add_runtime_dependency(%q<faraday-retry>.freeze, [">= 1"])
  s.add_runtime_dependency(%q<json>.freeze, ["< 3"])
  s.add_runtime_dependency(%q<marcel>.freeze, [">= 1.0", "< 3"])
  s.add_runtime_dependency(%q<schematist>.freeze, ["~> 1.1"])
  s.add_runtime_dependency(%q<zeitwerk>.freeze, ["~> 2"])
end
