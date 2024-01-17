# frozen_string_literal: true

require_relative "lib/pg_trigger/version"

Gem::Specification.new do |spec|
  spec.name = "rails-pg_trigger"
  spec.version = PgTrigger::VERSION
  spec.authors = ["ccocchi"]
  spec.email = ["cocchi.c@gmail.com"]

  spec.summary = "Postgres triggers for Rails"
  spec.description = "Write your Postgres triggers directly in your models."
  spec.homepage = "https://github.com/ccocchi/rails-pg_trigger"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/ccocchi/rails-pg_trigger/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test)/|\.(?:git|travis|circleci))})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.0", "< 8"
  spec.add_dependency "railties", ">= 7.0", "< 8"
  spec.add_dependency "pg", ">= 1.2.0", "< 2"
end
