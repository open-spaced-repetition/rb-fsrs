# frozen_string_literal: true

module Fsrs
  #
  ## Scheduling Info
  class SchedulingInfo
    attr_accessor :card, :review_log

    def initialize(card, review_log)
      @card = card
      @review_log = review_log
    end

    def to_h
      {
        card: @card.to_h,
        review_log: @review_log.to_h
      }
    end

    def self.from_h(hash)
      new(
        Fsrs::Card.from_h(hash[:card]),
        Fsrs::ReviewLog.from_h(hash[:review_log])
      )
    end
  end

  #
  ## Review Log
  class ReviewLog
    attr_accessor :rating, :scheduled_days, :elapsed_days, :review, :state

    def initialize(rating, scheduled_days, elapsed_days, review, state)
      @rating = rating
      @scheduled_days = scheduled_days
      @elapsed_days = elapsed_days
      @review = review
      @state = state
    end

    def to_h
      {
        rating: @rating,
        scheduled_days: @scheduled_days,
        elapsed_days: @elapsed_days,
        review: @review,
        state: @state
      }
    end

    def self.from_h(hash)
      new(
        hash[:rating],
        hash[:scheduled_days],
        hash[:elapsed_days],
        hash[:review],
        hash[:state]
      )
    end
  end

  #
  ## Determines next review date
  class CardScheduler
    attr_accessor :again, :hard, :good, :easy

    def initialize(card)
      @again = card.clone
      @hard = card.clone
      @good = card.clone
      @easy = card.clone
    end

    def update_state(state)
      case state
      when State::NEW
        update_new_state
      when State::LEARNING, State::RELEARNING
        update_learning_relearning_state(state)
      when State::REVIEW
        update_review_state
      end
    end

    def schedule(now, hard_interval, good_interval, easy_interval)
      update_schedule_days(hard_interval, good_interval, easy_interval)
      update_due_dates(now, hard_interval, good_interval, easy_interval)
    end

    def record_log(card, now)
      {
        Rating::AGAIN => record_again_log(card, now),
        Rating::HARD => record_hard_log(card, now),
        Rating::GOOD => record_good_log(card, now),
        Rating::EASY => record_easy_log(card, now)
      }
    end

    private

    def update_due_dates(now, hard_interval, good_interval, easy_interval)
      @again.due = now + 5.minutes
      @hard.due = hard_interval.positive? ? now + hard_interval.days : now + 10.minutes
      @good.due = now + good_interval.days
      @easy.due = now + easy_interval.days
    end

    def update_schedule_days(hard_interval, good_interval, easy_interval)
      @again.scheduled_days = 0
      @hard.scheduled_days = hard_interval
      @good.scheduled_days = good_interval
      @easy.scheduled_days = easy_interval
    end

    def update_new_state
      @again.state = State::LEARNING
      @hard.state = State::LEARNING
      @good.state = State::LEARNING
      @easy.state = State::REVIEW
    end

    def update_learning_relearning_state(state)
      @again.state = state
      @hard.state = state
      @good.state = State::REVIEW
      @easy.state = State::REVIEW
    end

    def update_review_state
      @again.state = State::RELEARNING
      @hard.state = State::REVIEW
      @good.state = State::REVIEW
      @easy.state = State::REVIEW
      @again.lapses += 1
    end

    def record_again_log(card, now)
      SchedulingInfo.new(
        @again,
        ReviewLog.new(
          Rating::AGAIN,
          @again.scheduled_days,
          card.elapsed_days,
          now,
          card.state
        )
      )
    end

    def record_hard_log(card, now)
      SchedulingInfo.new(
        @hard,
        ReviewLog.new(
          Rating::HARD,
          @hard.scheduled_days,
          card.elapsed_days,
          now,
          card.state
        )
      )
    end

    def record_good_log(card, now)
      SchedulingInfo.new(
        @good,
        ReviewLog.new(
          Rating::GOOD,
          @good.scheduled_days,
          card.elapsed_days,
          now,
          card.state
        )
      )
    end

    def record_easy_log(card, now)
      SchedulingInfo.new(
        @easy,
        ReviewLog.new(
          Rating::EASY,
          @easy.scheduled_days,
          card.elapsed_days,
          now,
          card.state
        )
      )
    end
  end

  #
  ## Rating
  class Rating
    AGAIN = 1
    HARD = 2
    GOOD = 3
    EASY = 4
  end

  #
  ## Card
  class Card
    attr_accessor :due, :stability, :difficulty, :elapsed_days, :scheduled_days, :reps, :lapses, :state, :last_review

    def initialize
      @due = DateTime.new
      @stability = 0.0
      @difficulty = 0.0
      @elapsed_days = 0
      @scheduled_days = 0
      @reps = 0
      @lapses = 0
      @state = State::NEW
    end

    def get_retrievability(now)
      decay = -0.5
      factor = (0.9**(1 / decay)) - 1

      return nil unless @state == State::REVIEW

      elapsed_days = [0, (now - @last_review).to_i].max
      (1 + (factor * elapsed_days / @stability))**decay
    end

    def deep_clone
      Marshal.load(Marshal.dump(self))
    end

    def to_h
      {
        state: @state, due: @due,
        stability: @stability, difficulty: @difficulty,
        elapsed_days: @elapsed_days, scheduled_days: @scheduled_days,
        reps: @reps, lapses: @lapses,
        last_review: @last_review
      }
    end

    def self.from_h(hash)
      card = new
      hash.each do |key, value|
        if %w[due last_review].include?(key) && value.is_a?(String)
          # Handle DateTime fields from JSON input
          card.instance_variable_set("@#{key}", DateTime.parse(value))
        else
          # Handle regular fields and DateTime objects from hash input
          card.instance_variable_set("@#{key}", value)
        end
      end
      card
    end
  end

  #
  ## State
  class State
    NEW = 0
    LEARNING = 1
    REVIEW = 2
    RELEARNING = 3
  end

  #
  ## Scheduler
  class Scheduler
    attr_accessor :p, :decay, :factor

    def initialize
      @p = Parameters.new
      @decay = -0.5
      @factor = (0.9**(1 / @decay)) - 1
    end

    def repeat(card, now)
      raise Fsrs::InvalidDateError unless now.utc?

      card = card.clone
      card.elapsed_days = card_elapsed_days(card, now)
      card.last_review = now
      card.reps += 1
      card_scheduler = CardScheduler.new(card)
      card_scheduler.update_state(card.state)

      schedule_card(card_scheduler, card, now)
      card_scheduler.record_log(card, now)
    end

    def card_elapsed_days(card, now)
      card.state == State::NEW ? 0 : (now - card.last_review).to_i
    end

    def schedule_card(card_scheduler, card, now)
      case card.state
      when State::NEW
        schedule_new_state(card_scheduler, now)
      when State::LEARNING, State::RELEARNING
        schedule_learning_relearning_state(card_scheduler, now)
      when State::REVIEW
        schedule_review_state(card_scheduler, card, now)
      end
    end

    module NewState # rubocop:disable Style/Documentation
      def schedule_new_state(s, now)
        init_ds(s)
        s.again.due = now + 60
        s.hard.due = now + (5 * 60)
        s.good.due = now + (10 * 60)
        easy_interval = next_interval(s.easy.stability)
        s.easy.scheduled_days = easy_interval
        s.easy.due = now + easy_interval.days
      end

      def init_ds(s)
        s.again.difficulty = init_difficulty(Rating::AGAIN)
        s.again.stability = init_stability(Rating::AGAIN)
        s.hard.difficulty = init_difficulty(Rating::HARD)
        s.hard.stability = init_stability(Rating::HARD)
        s.good.difficulty = init_difficulty(Rating::GOOD)
        s.good.stability = init_stability(Rating::GOOD)
        s.easy.difficulty = init_difficulty(Rating::EASY)
        s.easy.stability = init_stability(Rating::EASY)
      end

      def init_stability(r)
        [self.p.w[r - 1], 0.1].max
      end

      def init_difficulty(r)
        (self.p.w[4] - (self.p.w[5] * (r - 3))).clamp(1, 10)
      end
    end

    module LearningState # rubocop:disable Style/Documentation
      def schedule_learning_relearning_state(s, now)
        hard_interval = 0
        good_interval = next_interval(s.good.stability)
        easy_interval = [next_interval(s.easy.stability), good_interval + 1].max
        s.schedule(now, hard_interval, good_interval, easy_interval)
      end
    end

    module ReviewState # rubocop:disable Style/Documentation
      def schedule_review_state(s, card, now)
        interval = card.elapsed_days
        last_d = card.difficulty
        last_s = card.stability
        retrievability = forgetting_curve(interval, last_s)
        next_ds(s, last_d, last_s, retrievability)
        compute_review_state_intervals_and_schedule(s, now)
      end

      def forgetting_curve(elapsed_days, stability)
        (1 + (factor * elapsed_days / stability))**decay
      end

      def compute_review_state_intervals_and_schedule(s, now)
        hard_interval = next_interval(s.hard.stability)
        good_interval = next_interval(s.good.stability)
        hard_interval = [hard_interval, good_interval].min
        good_interval = [good_interval, hard_interval + 1].max
        easy_interval = [next_interval(s.easy.stability), good_interval + 1].max

        s.schedule(now, hard_interval, good_interval, easy_interval)
      end

      def mean_reversion(init, current)
        (self.p.w[7] * init) + ((1 - self.p.w[7]) * current)
      end
    end

    module Common # rubocop:disable Style/Documentation
      def next_ds(s, last_d, last_s, retrievability)
        s.again.difficulty = next_difficulty(last_d, Rating::AGAIN)
        s.again.stability = next_forget_stability(last_d, last_s, retrievability)
        s.hard.difficulty = next_difficulty(last_d, Rating::HARD)
        s.hard.stability = next_recall_stability(last_d, last_s, retrievability, Rating::HARD)
        s.good.difficulty = next_difficulty(last_d, Rating::GOOD)
        s.good.stability = next_recall_stability(last_d, last_s, retrievability, Rating::GOOD)
        s.easy.difficulty = next_difficulty(last_d, Rating::EASY)
        s.easy.stability = next_recall_stability(last_d, last_s, retrievability, Rating::EASY)
      end

      def next_difficulty(d, r)
        next_d = d - (self.p.w[6] * (r - 3))
        mean_reversion(self.p.w[4], next_d).clamp(1, 10)
      end

      def next_recall_stability(d, s, r, rating)
        hard_penalty = rating == Rating::HARD ? self.p.w[15] : 1
        easy_bonus = rating == Rating::EASY ? self.p.w[16] : 1
        s * (1 + (Math.exp(self.p.w[8]) * (11 - d) * (s**-self.p.w[9]) *
            (Math.exp((1 - r) * self.p.w[10]) - 1) * hard_penalty * easy_bonus))
      end

      def next_forget_stability(d, s, r)
        self.p.w[11] * (d**-self.p.w[12]) * (((s + 1)**self.p.w[13]) - 1) *
          Math.exp((1 - r) * self.p.w[14])
      end

      def next_interval(s)
        new_interval = s / factor * ((self.p.request_retention**(1 / decay)) - 1)
        new_interval.round.clamp(1, self.p.maximum_interval)
      end
    end

    module Serialization # rubocop:disable Style/Documentation
      def to_h
        {
          p: @p.to_h,
          decay: @decay,
          factor: @factor
        }
      end

      module ClassMethods # rubocop:disable Style/Documentation
        def from_h(hash)
          scheduler = new
          scheduler.p = Parameters.from_h(hash[:p])
          scheduler.decay = hash[:decay]
          scheduler.factor = hash[:factor]
          scheduler
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end
    end

    include NewState
    include LearningState
    include ReviewState
    include Common
    include Serialization
  end

  #
  ## Parameters
  class Parameters
    attr_accessor :request_retention, :maximum_interval, :w

    def initialize
      @request_retention = 0.9
      @maximum_interval = 36_500
      @w = [0.4, 0.6, 2.4, 5.8, 4.93, 0.94, 0.86, 0.01, 1.49, 0.14, 0.94,
            2.18, 0.05, 0.34, 1.26, 0.29, 2.61]
    end

    def to_h
      {
        request_retention: @request_retention,
        maximum_interval: @maximum_interval,
        w: @w
      }
    end

    def self.from_h(hash)
      params = new
      params.w = hash[:w]
      params.request_retention = hash[:request_retention]
      params.maximum_interval = hash[:maximum_interval]
      params
    end
  end
end
