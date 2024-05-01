## About The Project

rb-fsrs is a Ruby Gem implements [Free Spaced Repetition Scheduler algorithm](https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler). It helps developers apply FSRS in their flashcard apps.

## Getting Started

```
gem install fsrs
```

or 

```
bundle add fsrs
```

## Usage

Create a card and review it at a given time:
```ruby
require 'fsrs'

scheduler = Fsrs::Scheduler.new
card = Fsrs::Card.new
now = DateTime.now.utc
scheduling_cards = scheduler.repeat(card, now)
```

There are four ratings:
```ruby
Rating::AGAIN # forget; incorrect response
Rating::HARD # recall; correct response recalled with serious difficulty
Rating::GOOD # recall; correct response after a hesitation
Rating::EASY # recall; perfect response
```


Get the new state of card for each rating:
```ruby
scheduling_cards[Rating::AGAIN].card
scheduling_cards[Rating::HARD].card
scheduling_cards[Rating::GOOD].card
scheduling_cards[Rating::EASY].card
```

Get the scheduled days for each rating:
```ruby
card_again.scheduled_days
card_hard.scheduled_days
card_good.scheduled_days
card_easy.scheduled_days
```

Update the card after rating `GOOD`:
```ruby
card = scheduling_cards[Rating::GOOD].card
```

Get the review log after rating `GOOD`:
```ruby
review_log = scheduling_cards[Rating::GOOD].review_log
```

Get the due date for card:
```ruby
due = card.due
```

There are four states:
```ruby
State::NEW # Never been studied
State::LEARNING # Been studied for the first time recently
State::REVIEW # Graduate from learning state
State::RELEARNING # Forgotten in review state
```

## Acknowledgements

* [Open Spaced Repetition](https://github.com/open-spaced-repetition)
* [py-fsrs](https://github.com/open-spaced-repetition/py-fsrs)

This library was ported from [py-fsrs](https://github.com/open-spaced-repetition/py-fsrs) to Ruby. Much refactoring to be done, but the core logic is the same.

## License

Distributed under the MIT License. See `LICENSE` for more information.