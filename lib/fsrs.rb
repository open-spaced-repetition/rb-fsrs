# frozen_string_literal: true

require "active_support/deprecator"
require "active_support/deprecation"
require "active_support/time"
require "active_support/time_with_zone"

require_relative "fsrs/version"
require_relative "fsrs/fsrs"

module Fsrs
  class Error < StandardError; end

  class InvalidDateError < Error
    def initialize(msg = "Date must be UTC and timezone-aware")
      super
    end
  end
end
