# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::TokenBucket do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end

  describe Philiprehberger::TokenBucket::Bucket do
    subject(:bucket) { described_class.new(capacity: 10, refill_rate: 100) }

    describe '.new' do
      it 'creates a bucket with given capacity' do
        expect(bucket.available).to eq(10.0)
      end

      it 'raises for non-positive capacity' do
        expect { described_class.new(capacity: 0, refill_rate: 1) }
          .to raise_error(Philiprehberger::TokenBucket::Error)
      end

      it 'raises for non-positive refill rate' do
        expect { described_class.new(capacity: 10, refill_rate: 0) }
          .to raise_error(Philiprehberger::TokenBucket::Error)
      end

      it 'raises for negative capacity' do
        expect { described_class.new(capacity: -5, refill_rate: 1) }
          .to raise_error(Philiprehberger::TokenBucket::Error)
      end

      it 'raises for negative refill rate' do
        expect { described_class.new(capacity: 10, refill_rate: -1) }
          .to raise_error(Philiprehberger::TokenBucket::Error)
      end

      it 'starts with full capacity' do
        b = described_class.new(capacity: 50, refill_rate: 10)
        expect(b.available).to eq(50.0)
      end

      it 'accepts float capacity' do
        b = described_class.new(capacity: 5.5, refill_rate: 1)
        expect(b.available).to eq(5.5)
      end

      it 'accepts float refill rate' do
        b = described_class.new(capacity: 10, refill_rate: 0.5)
        expect(b.available).to eq(10.0)
      end
    end

    describe '#try_take' do
      it 'returns true when tokens are available' do
        expect(bucket.try_take(5)).to be true
      end

      it 'reduces available tokens' do
        bucket.try_take(3)
        expect(bucket.available).to be_within(0.1).of(7.0)
      end

      it 'returns false when not enough tokens' do
        expect(bucket.try_take(11)).to be false
      end

      it 'defaults to taking 1 token' do
        expect(bucket.try_take).to be true
        expect(bucket.available).to be_within(0.1).of(9.0)
      end

      it 'returns true when taking exactly available amount' do
        expect(bucket.try_take(10)).to be true
      end

      it 'returns false after tokens are exhausted' do
        bucket.try_take(10)
        expect(bucket.try_take(1)).to be false
      end

      it 'allows multiple partial takes' do
        expect(bucket.try_take(3)).to be true
        expect(bucket.try_take(3)).to be true
        expect(bucket.try_take(3)).to be true
        expect(bucket.try_take(3)).to be false
      end

      it 'does not reduce tokens on failure' do
        bucket.try_take(8)
        before = bucket.available
        bucket.try_take(20)
        expect(bucket.available).to be_within(0.5).of(before)
      end
    end

    describe '#take' do
      it 'takes tokens when available' do
        bucket.take(5)
        expect(bucket.available).to be_within(0.1).of(5.0)
      end

      it 'raises when n exceeds capacity' do
        expect { bucket.take(11) }.to raise_error(Philiprehberger::TokenBucket::Error)
      end

      it 'includes capacity in error message when exceeding' do
        expect { bucket.take(15) }.to raise_error(
          Philiprehberger::TokenBucket::Error,
          /cannot take 15 tokens from bucket with capacity 10/
        )
      end

      it 'blocks until tokens are available' do
        bucket.try_take(10)
        # With refill_rate of 100/s, 1 token should be available in ~10ms
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        bucket.take(1)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        expect(elapsed).to be < 0.5
      end

      it 'defaults to taking 1 token' do
        bucket.take
        expect(bucket.available).to be_within(0.1).of(9.0)
      end

      it 'takes exact capacity' do
        bucket.take(10)
        expect(bucket.available).to be_within(0.1).of(0.0)
      end
    end

    describe '#available' do
      it 'returns current token count' do
        expect(bucket.available).to eq(10.0)
      end

      it 'refills over time' do
        bucket.try_take(10)
        sleep(0.05)
        expect(bucket.available).to be > 0
      end

      it 'does not exceed capacity' do
        sleep(0.1)
        expect(bucket.available).to be <= 10.0
      end

      it 'returns a Float' do
        expect(bucket.available).to be_a(Float)
      end

      it 'returns zero immediately after draining' do
        bucket.try_take(10)
        expect(bucket.available).to be_within(0.5).of(0.0)
      end
    end

    describe '#wait_time' do
      it 'returns 0 when tokens are available' do
        expect(bucket.wait_time(5)).to eq(0.0)
      end

      it 'returns positive time when tokens are insufficient' do
        bucket.try_take(10)
        expect(bucket.wait_time(5)).to be > 0
      end

      it 'defaults to 1 token' do
        expect(bucket.wait_time).to eq(0.0)
      end

      it 'returns 0 for zero tokens needed when bucket is full' do
        expect(bucket.wait_time(0)).to eq(0.0)
      end

      it 'returns proportional wait time based on deficit' do
        b = described_class.new(capacity: 10, refill_rate: 10)
        b.try_take(10)
        wait = b.wait_time(5)
        expect(wait).to be_within(0.1).of(0.5)
      end

      it 'returns a Float' do
        expect(bucket.wait_time).to be_a(Float)
      end
    end

    describe 'thread safety' do
      it 'handles concurrent access' do
        b = described_class.new(capacity: 100, refill_rate: 1000)
        results = Array.new(10) do
          Thread.new { b.try_take(10) }
        end.map(&:value)
        expect(results.count(true)).to be <= 10
      end

      it 'never goes below zero available' do
        b = described_class.new(capacity: 10, refill_rate: 1)
        threads = Array.new(20) do
          Thread.new { b.try_take(1) }
        end
        threads.each(&:join)
        expect(b.available).to be >= 0.0
      end
    end

    describe 'strategy: :smooth' do
      it 'is the default and refills continuously' do
        b = described_class.new(capacity: 10, refill_rate: 100)
        b.try_take(5)
        sleep(0.02)
        tokens = b.available
        expect(tokens).to be > 5.0
        expect(tokens).to be <= 10.0
      end
    end

    describe 'strategy: :interval' do
      it 'does not refill between intervals' do
        b = described_class.new(capacity: 10, refill_rate: 10, strategy: :interval)
        b.try_take(5)
        sleep(0.05)
        expect(b.available).to be_within(0.1).of(5.0)
      end

      it 'refills to full capacity after interval elapses' do
        b = described_class.new(capacity: 10, refill_rate: 100, strategy: :interval)
        b.try_take(5)
        # interval = capacity / refill_rate = 10/100 = 0.1s
        sleep(0.15)
        expect(b.available).to eq(10.0)
      end

      it 'raises for invalid strategy' do
        expect { described_class.new(capacity: 10, refill_rate: 1, strategy: :bogus) }
          .to raise_error(Philiprehberger::TokenBucket::Error, /unknown strategy/)
      end
    end

    describe '#reset' do
      it 'restores tokens to full capacity' do
        bucket.try_take(8)
        bucket.reset
        expect(bucket.available).to eq(10.0)
      end

      it 'returns self' do
        expect(bucket.reset).to be(bucket)
      end

      it 'resets the refill timer' do
        bucket.try_take(10)
        bucket.reset
        bucket.try_take(10)
        # After reset + immediate drain, refill should start from now
        expect(bucket.available).to be_within(0.5).of(0.0)
      end
    end

    describe '#refill_rate' do
      it 'exposes the refill rate as a reader' do
        expect(bucket.refill_rate).to eq(100.0)
      end
    end

    describe '#strategy' do
      it 'returns the default strategy' do
        expect(bucket.strategy).to eq(:smooth)
      end

      it 'returns the configured strategy' do
        b = described_class.new(capacity: 10, refill_rate: 10, strategy: :interval)
        expect(b.strategy).to eq(:interval)
      end
    end

    describe '#drain' do
      it 'empties all tokens' do
        bucket.drain
        expect(bucket.available).to be_within(0.5).of(0.0)
      end

      it 'returns self' do
        expect(bucket.drain).to be(bucket)
      end
    end

    describe '#full?' do
      it 'returns true when bucket is full' do
        expect(bucket.full?).to be true
      end

      it 'returns false after taking tokens' do
        bucket.try_take(5)
        expect(bucket.full?).to be false
      end
    end

    describe '#capacity' do
      it 'exposes the capacity as a reader' do
        expect(bucket.capacity).to eq(10.0)
      end
    end

    describe 'refill behavior' do
      it 'refills tokens after consumption' do
        b = described_class.new(capacity: 10, refill_rate: 1000)
        b.try_take(5)
        sleep(0.01)
        expect(b.available).to be > 5.0
      end

      it 'caps refill at capacity' do
        b = described_class.new(capacity: 5, refill_rate: 1000)
        sleep(0.1)
        expect(b.available).to eq(5.0)
      end
    end

    describe '#stats' do
      it 'returns a hash with the expected keys' do
        expect(bucket.stats.keys).to contain_exactly(:available, :capacity, :refill_rate, :strategy)
      end

      it 'reports capacity, refill_rate, and strategy from the constructor' do
        b = described_class.new(capacity: 20, refill_rate: 5, strategy: :interval)
        stats = b.stats
        expect(stats[:capacity]).to eq(20.0)
        expect(stats[:refill_rate]).to eq(5.0)
        expect(stats[:strategy]).to eq(:interval)
      end

      it 'reports available tokens at call time' do
        bucket.try_take(4)
        expect(bucket.stats[:available]).to be_within(0.1).of(6.0)
      end

      it 'returns Float values for numeric fields' do
        stats = bucket.stats
        expect(stats[:available]).to be_a(Float)
        expect(stats[:capacity]).to be_a(Float)
        expect(stats[:refill_rate]).to be_a(Float)
      end

      it 'returns a Symbol for strategy' do
        expect(bucket.stats[:strategy]).to be_a(Symbol)
      end

      it 'returns a frozen hash' do
        expect(bucket.stats).to be_frozen
      end
    end

    describe '#take_wait_timeout' do
      it 'returns true when tokens are available immediately' do
        expect(bucket.take_wait_timeout(5, timeout: 1.0)).to be true
      end

      it 'consumes the tokens on success' do
        bucket.take_wait_timeout(3, timeout: 1.0)
        expect(bucket.available).to be_within(0.1).of(7.0)
      end

      it 'defaults to taking 1 token' do
        expect(bucket.take_wait_timeout(timeout: 1.0)).to be true
        expect(bucket.available).to be_within(0.1).of(9.0)
      end

      it 'raises when tokens cannot be replenished before timeout' do
        b = described_class.new(capacity: 10, refill_rate: 1)
        b.try_take(10)
        expect { b.take_wait_timeout(5, timeout: 0.05) }
          .to raise_error(Philiprehberger::TokenBucket::Error, /timed out waiting for 5 tokens/)
      end

      it 'raises when n exceeds capacity' do
        expect { bucket.take_wait_timeout(11, timeout: 1.0) }
          .to raise_error(Philiprehberger::TokenBucket::Error, /cannot take 11 tokens/)
      end

      it 'blocks briefly then succeeds when refill completes in time' do
        b = described_class.new(capacity: 10, refill_rate: 100)
        b.try_take(10)
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        expect(b.take_wait_timeout(1, timeout: 1.0)).to be true
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        expect(elapsed).to be < 0.5
        expect(elapsed).to be >= 0.005
      end

      it 'does not double-consume under concurrent calls' do
        b = described_class.new(capacity: 5, refill_rate: 1)
        threads = Array.new(10) do
          Thread.new do
            b.take_wait_timeout(1, timeout: 0.05)
            :ok
          rescue Philiprehberger::TokenBucket::Error
            :timeout
          end
        end
        results = threads.map(&:value)
        expect(results.count(:ok)).to be <= 5
        expect(b.available).to be >= 0.0
      end
    end
  end
end
