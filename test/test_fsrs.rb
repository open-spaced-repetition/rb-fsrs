# frozen_string_literal: true

require "test_helper"

class FSRSTest < Minitest::Test
  def test_repeat
    f = Fsrs::Scheduler.new
    f.p.w = [
      1.14,
      1.01,
      5.44,
      14.67,
      5.3024,
      1.5662,
      1.2503,
      0.0028,
      1.5489,
      0.1763,
      0.9953,
      2.7473,
      0.0179,
      0.3105,
      0.3976,
      0.0,
      2.0902
    ]

    card = Fsrs::Card.new
    now = DateTime.parse("2022-11-29 12:30 +00:00")
    scheduling_cards = f.repeat(card, now)
    # print_scheduling_cards(scheduling_cards)

    ratings = [
      Fsrs::Rating::GOOD,
      Fsrs::Rating::GOOD,
      Fsrs::Rating::GOOD,
      Fsrs::Rating::GOOD,
      Fsrs::Rating::GOOD,
      Fsrs::Rating::GOOD,
      Fsrs::Rating::AGAIN,
      Fsrs::Rating::AGAIN,
      Fsrs::Rating::GOOD,
      Fsrs::Rating::GOOD,
      Fsrs::Rating::GOOD,
      Fsrs::Rating::GOOD,
      Fsrs::Rating::GOOD
    ]
    ivl_history = []

    ratings.each do |rating|
      card = scheduling_cards[rating].card
      ivl = card.scheduled_days
      ivl_history.push(ivl)
      now = card.due
      scheduling_cards = f.repeat(card, now)
      # print_scheduling_cards(scheduling_cards)
    end

    assert_equal [0, 5, 16, 43, 106, 236, 0, 0, 12, 25, 47, 85, 147], ivl_history
  end

  def test_datetime
    f = Fsrs::Scheduler.new
    card = Fsrs::Card.new

    # new cards should be due immediately after creation
    assert card.due >= DateTime.new

    # repeating a card with a non-UTC, non-timezone-aware datetime object should raise a Value Error
    assert_raises Fsrs::InvalidDateError do
      f.repeat(card, DateTime.parse("2022-11-29 12:30 +05:00"))
    end

    # repeat a card with rating good before next tests
    scheduling_cards = f.repeat(card, DateTime.now.utc)
    card = scheduling_cards[Fsrs::Rating::GOOD].card

    # card object's due and last_review attributes must be timezone aware and UTC
    assert_equal "UTC", card.due.zone
    assert_equal "UTC", card.last_review.zone

    # card object's due datetime should be later than its last review
    assert card.due >= card.last_review
  end
end
