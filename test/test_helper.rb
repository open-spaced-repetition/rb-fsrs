# frozen_string_literal: true

require "simplecov"
SimpleCov.external_at_exit = true
SimpleCov.start do
  root File.expand_path("..", __dir__)

  add_filter "/test/"
  enable_coverage :branch
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "fsrs"

require "minitest/autorun"
require "minitest/pride"

def print_scheduling_cards(scheduling_cards)
  # Useful for debugging
  #
  %i[again hard good easy].each do |state|
    puts scheduling_cards[Fsrs::Rating.const_get(state.upcase.to_sym)]
      .card.inspect
    puts scheduling_cards[Fsrs::Rating.const_get(state.upcase.to_sym)]
      .review_log.inspect
  end
end
