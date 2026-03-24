# philiprehberger-token_bucket

[![Tests](https://github.com/philiprehberger/rb-token-bucket/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-token-bucket/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-token_bucket.svg)](https://rubygems.org/gems/philiprehberger-token_bucket)
[![License](https://img.shields.io/github/license/philiprehberger/rb-token-bucket)](LICENSE)

Token bucket rate limiter with configurable capacity and refill rate

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-token_bucket"
```

Or install directly:

```bash
gem install philiprehberger-token_bucket
```

## Usage

```ruby
require 'philiprehberger/token_bucket'

bucket = Philiprehberger::TokenBucket::Bucket.new(capacity: 10, refill_rate: 5)
```

### Blocking Take

```ruby
bucket.take(3)    # blocks until 3 tokens are available, then consumes them
bucket.take       # takes 1 token by default
```

### Non-blocking Take

```ruby
if bucket.try_take(2)
  # tokens acquired, proceed
else
  # not enough tokens, try again later
end
```

### Checking Availability

```ruby
bucket.available   # => current number of tokens (Float)
bucket.wait_time(5) # => seconds until 5 tokens will be available
```

## API

### `Philiprehberger::TokenBucket::Bucket`

| Method | Description |
|--------|-------------|
| `.new(capacity:, refill_rate:)` | Create a bucket with max tokens and tokens-per-second refill |
| `#take(n = 1)` | Block until n tokens are available, then consume them |
| `#try_take(n = 1)` | Consume n tokens if available, return true/false |
| `#available` | Return the current number of available tokens |
| `#wait_time(n = 1)` | Estimate seconds until n tokens will be available |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
