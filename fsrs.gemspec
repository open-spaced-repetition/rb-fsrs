# frozen_string_literal: true

require_relative "lib/fsrs/version"

Gem::Specification.new do |spec|
  spec.name = "fsrs"
  spec.version = Fsrs::VERSION
  spec.authors = ["clayton"]
  spec.email = ["6334+clayton@users.noreply.github.com"]

  spec.summary = "Ruby implementation of FSRS algorithm."
  spec.description = "A ruby implementation of the Open Spaced Repetition's Free Spaced Repetition Scheduler."
  spec.homepage = "https://github.com/clayton/rb-fsrs"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/clayton/rb-fsrs"
  spec.metadata["changelog_uri"] = "https://github.com/clayton/rb-fsrs/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "activesupport", "~> 7.0"

  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-minitest"
  spec.add_development_dependency "rubocop-rake"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
