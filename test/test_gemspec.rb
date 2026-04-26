# frozen_string_literal: true

require "test_helper"

class GemspecTest < Minitest::Test
  def test_activesupport_dependency_allows_rails_eight
    dependency = fsrs_gemspec.dependencies.find { |dep| dep.name == "activesupport" }

    assert dependency.requirement.satisfied_by?(Gem::Version.new("7.0.0"))
    assert dependency.requirement.satisfied_by?(Gem::Version.new("8.0.2"))
    assert dependency.requirement.satisfied_by?(Gem::Version.new("8.1.0"))
    refute dependency.requirement.satisfied_by?(Gem::Version.new("9.0.0"))
  end

  private

  def fsrs_gemspec
    Gem::Specification.load(File.expand_path("../fsrs.gemspec", __dir__))
  end
end
