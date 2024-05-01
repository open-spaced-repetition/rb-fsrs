# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require 'minitest/pride'

Minitest::TestTask.create

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[test rubocop]
