# philiprehberger-token_bucket

[![Tests](https://github.com/philiprehberger/rb-token-bucket/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-token-bucket/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-token_bucket.svg)](https://rubygems.org/gems/philiprehberger-token_bucket)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-token-bucket)](https://github.com/philiprehberger/rb-token-bucket/commits/main)

Thread-safe token bucket rate limiter with configurable capacity, refill rate, and refill strategy

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

### Basic usage

```ruby
require "philiprehberger/token_bucket"

bucket = Philiprehberger::TokenBucket::Bucket.new(capacity: 10, refill_rate: 5)

bucket.take(3)     # blocks until 3 tokens are available
bucket.try_take(2) # returns true/false without blocking
bucket.available   # current token count
bucket.wait_time(5) # seconds until 5 tokens are available
```

### Interval strategy

```ruby
bucket = Philiprehberger::TokenBucket::Bucket.new(
  capacity: 100,
  refill_rate: 10,
  strategy: :interval
)

# Tokens refill in bursts: full capacity restored every capacity/refill_rate seconds (10s here).
# No tokens are added between intervals.
bucket.try_take(50)
bucket.available # => 50.0 (no partial refill until the interval elapses)
```

### Drain and full?

```ruby
bucket = Philiprehberger::TokenBucket::Bucket.new(capacity: 10, refill_rate: 5)

bucket.full?  # => true
bucket.drain  # empties all tokens, returns self
bucket.full?  # => false
```

## API

### `Philiprehberger::TokenBucket::Bucket`

| Method | Description |
|--------|-------------|
| `.new(capacity:, refill_rate:, strategy: :smooth)` | Create a bucket. `strategy` accepts `:smooth` (continuous refill) or `:interval` (burst refill). Raises `Error` if arguments are invalid |
| `#take(n = 1)` | Block until n tokens are available, then consume them. Raises `Error` if n exceeds capacity |
| `#try_take(n = 1)` | Consume n tokens if available, return `true`/`false` without blocking |
| `#available` | Return the current number of available tokens as a `Float` |
| `#wait_time(n = 1)` | Estimate seconds until n tokens will be available. Returns `0.0` if already available |
| `#drain` | Set available tokens to zero. Returns `self` |
| `#full?` | Return `true` when available tokens >= capacity |
| `#capacity` | Return the maximum token capacity as a `Float` |

### `Philiprehberger::TokenBucket::Error`

| Constant / Class | Description |
|------------------|-------------|
| `Error` | Raised for invalid arguments (non-positive capacity/refill_rate, unknown strategy) or when `#take` exceeds capacity |
| `VERSION` | Current gem version string (e.g. `"0.2.0"`) |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-token-bucket)

🐛 [Report issues](https://github.com/philiprehberger/rb-token-bucket/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-token-bucket/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
