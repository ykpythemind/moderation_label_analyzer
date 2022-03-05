# frozen_string_literal: true

require_relative "lib/moderation_label_analyzer/version"

Gem::Specification.new do |spec|
  spec.name          = "moderation_label_analyzer"
  spec.version       = ModerationLabelAnalyzer::VERSION
  spec.authors       = ["ykpythemind"]
  spec.email         = ["yukibukiyou@gmail.com"]

  spec.summary       = "Provide ModerationLabelAnalyzer as ActiveStorage::Analyzer"
  spec.description   = "ModerationLabelAnalyzer analyze moderation labels by Amazon Rekognition"
  spec.homepage      = "https://github.com/ykpythemind/moderation_label_analyzer"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'https://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ykpythemind/moderation_label_analyzer"
  spec.metadata["changelog_uri"] = "https://github.com/ykpythemind/moderation_label_analyzer"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "aws-sdk-rekognition", "~> 1"
  spec.add_dependency "nokogiri", "~> 1"

  spec.add_development_dependency "rails", "~> 6"
  spec.add_development_dependency "sqlite3", "~> 1.3"
  spec.add_development_dependency "aws-sdk-s3"
end
