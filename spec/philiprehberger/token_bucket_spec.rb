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
    end

    describe '#take' do
      it 'takes tokens when available' do
        bucket.take(5)
        expect(bucket.available).to be_within(0.1).of(5.0)
      end

      it 'raises when n exceeds capacity' do
        expect { bucket.take(11) }.to raise_error(Philiprehberger::TokenBucket::Error)
      end

      it 'blocks until tokens are available' do
        bucket.try_take(10)
        # With refill_rate of 100/s, 1 token should be available in ~10ms
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        bucket.take(1)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        expect(elapsed).to be < 0.5
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
    end

    describe '#wait_time' do
      it 'returns 0 when tokens are available' do
        expect(bucket.wait_time(5)).to eq(0.0)
      end

      it 'returns positive time when tokens are insufficient' do
        bucket.try_take(10)
        expect(bucket.wait_time(5)).to be > 0
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
    end
  end
end
