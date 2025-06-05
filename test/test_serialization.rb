# frozen_string_literal: true

require "test_helper"
require "json"

class SerializationTest < Minitest::Test
  def setup
    @now = DateTime.now
  end

  def test_card_serialization_roundtrip
    # 1. Create object using helper
    original = create_test_card

    # 2. Serialize with to_h and to_json
    serialized_hash = original.to_h
    serialized_json = original.to_h.to_json

    # 3. Deserialize and verify
    restored_from_hash = Fsrs::Card.from_h(serialized_hash)
    restored_from_json = Fsrs::Card.from_h(JSON.parse(serialized_json))

    # Verify properties using helper
    assert_card_properties_equal(original, restored_from_hash)
    assert_card_properties_equal(original, restored_from_json)
  end

  def test_scheduler_serialization_roundtrip
    # 1. Create and modify
    original = Fsrs::Scheduler.new
    original.p.w = [1.1, 2.2, 3.3, 4.4]
    original.decay = -0.7
    original.factor = 1.2

    # 2. Test JSON roundtrip
    json_string = original.to_h.to_json
    parsed_hash = JSON.parse(json_string, symbolize_names: true)
    restored = Fsrs::Scheduler.from_h(parsed_hash)

    assert_equal original.p.w, restored.p.w
    assert_equal original.decay, restored.decay
    assert_equal original.factor, restored.factor
  end

  def test_parameters_serialization_roundtrip
    # 1. Create and modify
    original = Fsrs::Parameters.new
    original.w = [1.0, 2.0, 3.0]
    original.request_retention = 0.8
    original.maximum_interval = 1000

    # 2. Serialize
    serialized = original.to_h

    # 3. Deserialize
    restored = Fsrs::Parameters.from_h(serialized)

    # 4. Verify all properties
    assert_equal original.w, restored.w
    assert_equal original.request_retention, restored.request_retention
    assert_equal original.maximum_interval, restored.maximum_interval
  end

  def test_review_log_serialization_roundtrip
    original = Fsrs::ReviewLog.new(
      Fsrs::Rating::GOOD,
      10,
      5,
      @now,
      Fsrs::State::REVIEW
    )

    serialized = original.to_h
    restored = Fsrs::ReviewLog.from_h(serialized)

    assert_equal original.rating, restored.rating
    assert_equal original.scheduled_days, restored.scheduled_days
    assert_equal original.elapsed_days, restored.elapsed_days
    assert_equal original.review, restored.review
    assert_equal original.state, restored.state
  end

  def test_scheduling_info_serialization_roundtrip
    # 1. Create test objects
    card = create_test_card
    log = Fsrs::ReviewLog.new(Fsrs::Rating::EASY, 15, 3, @now, Fsrs::State::REVIEW)
    original = Fsrs::SchedulingInfo.new(card, log)

    # 2. Test hash roundtrip
    restored = Fsrs::SchedulingInfo.from_h(original.to_h)
    assert_equal original.card.to_h, restored.card.to_h
    assert_equal original.review_log.to_h, restored.review_log.to_h

    # 3. Test JSON roundtrip (compare string representations)
    json_restored = Fsrs::SchedulingInfo.from_h(JSON.parse(original.to_h.to_json, symbolize_names: true))
    assert_equal original.to_h.to_json, json_restored.to_h.to_json
  end

  private

  def create_test_card
    card = Fsrs::Card.new
    card.state = Fsrs::State::REVIEW
    card.due = @now
    card.stability = 1.5
    card.difficulty = 3.2
    card.elapsed_days = 5
    card.scheduled_days = 10
    card.reps = 3
    card.lapses = 1
    card.last_review = @now - 5
    card
  end

  def assert_card_properties_equal(original, restored)
    assert_equal original.state, restored.state
    assert_equal original.due.inspect, restored.due.inspect
    assert_equal original.stability, restored.stability
    assert_equal original.difficulty, restored.difficulty
    assert_equal original.elapsed_days, restored.elapsed_days
    assert_equal original.scheduled_days, restored.scheduled_days
    assert_equal original.reps, restored.reps
    assert_equal original.lapses, restored.lapses
    assert_equal original.last_review.inspect, restored.last_review.inspect
  end
end
