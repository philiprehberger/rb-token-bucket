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

### Drain, reset, and full?

```ruby
bucket = Philiprehberger::TokenBucket::Bucket.new(capacity: 10, refill_rate: 5)

bucket.full?  # => true
bucket.drain  # empties all tokens, returns self
bucket.full?  # => false
bucket.reset  # restores to full capacity, returns self
bucket.full?  # => true
```

### Inspect state

```ruby
bucket = Philiprehberger::TokenBucket::Bucket.new(capacity: 10, refill_rate: 5)

bucket.stats
# => { available: 10.0, capacity: 10.0, refill_rate: 5.0, strategy: :smooth }
# The returned hash is frozen.
```

### Wait with timeout

```ruby
bucket = Philiprehberger::TokenBucket::Bucket.new(capacity: 10, refill_rate: 5)

# Block up to 2 seconds waiting for 5 tokens. Returns true on success,
# raises Philiprehberger::TokenBucket::Error if the timeout elapses first.
bucket.take_wait_timeout(5, timeout: 2.0)
```

## API

### `Philiprehberger::TokenBucket::Bucket`

| Method | Description |
|--------|-------------|
| `.new(capacity:, refill_rate:, strategy: :smooth)` | Create a bucket. `strategy` accepts `:smooth` (continuous refill) or `:interval` (burst refill). Raises `Error` if arguments are invalid |
| `#take(n = 1)` | Block until n tokens are available, then consume them. Raises `Error` if n exceeds capacity |
| `#try_take(n = 1)` | Consume n tokens if available, return `true`/`false` without blocking |
| `#take_wait_timeout(n = 1, timeout:)` | Block up to `timeout` seconds waiting for n tokens. Returns `true` on success, raises `Error` on timeout or if n exceeds capacity |
| `#available` | Return the current number of available tokens as a `Float` |
| `#wait_time(n = 1)` | Estimate seconds until n tokens will be available. Returns `0.0` if already available |
| `#drain` | Set available tokens to zero. Returns `self` |
| `#reset` | Restore tokens to full capacity and reset the refill timer. Returns `self` |
| `#full?` | Return `true` when available tokens >= capacity |
| `#stats` | Return a frozen hash snapshot `{ available:, capacity:, refill_rate:, strategy: }` |
| `#capacity` | Return the maximum token capacity as a `Float` |
| `#refill_rate` | Return the refill rate (tokens per second) as a `Float` |
| `#strategy` | Return the refill strategy (`:smooth` or `:interval`) |

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
