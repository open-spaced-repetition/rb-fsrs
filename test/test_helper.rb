# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "fsrs"

require "minitest/autorun"
require "minitest/pride"

def print_scheduling_cards(scheduling_cards)
  %i[again hard good easy].each do |state|
    puts "#{state}.card: #{scheduling_cards.dig(Fsrs::Rating.const_get(state.upcase.to_sym)).card.scheduled_days}"
    # puts "#{state}.review_log: #{scheduling_cards.dig(Fsrs::Rating.const_get(state.upcase.to_sym)).review_log.inspect}"  
  end
  puts '--------------------------'
end