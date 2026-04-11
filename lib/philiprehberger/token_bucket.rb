# frozen_string_literal: true

require_relative 'token_bucket/version'

module Philiprehberger
  module TokenBucket
    class Error < StandardError; end

    STRATEGIES = %i[smooth interval].freeze

    # A thread-safe token bucket rate limiter
    class Bucket
      attr_reader :capacity, :refill_rate, :strategy

      # @param capacity [Numeric] maximum number of tokens
      # @param refill_rate [Numeric] tokens added per second
      # @param strategy [Symbol] :smooth (continuous) or :interval (burst refill)
      def initialize(capacity:, refill_rate:, strategy: :smooth)
        raise Error, 'capacity must be positive' unless capacity.positive?
        raise Error, 'refill_rate must be positive' unless refill_rate.positive?
        raise Error, "unknown strategy: #{strategy}" unless STRATEGIES.include?(strategy)

        @capacity = capacity.to_f
        @refill_rate = refill_rate.to_f
        @strategy = strategy
        @tokens = @capacity
        @last_refill = now
        @refill_interval = @capacity / @refill_rate
        @mutex = Mutex.new
      end

      # Take n tokens, blocking until they are available
      #
      # @param n [Numeric] number of tokens to take
      # @return [void]
      # @raise [Error] if n exceeds capacity
      def take(n = 1)
        raise Error, "cannot take #{n} tokens from bucket with capacity #{@capacity}" if n > @capacity

        loop do
          wait = nil
          @mutex.synchronize do
            refill
            if @tokens >= n
              @tokens -= n
              return
            end
            wait = compute_wait_time(n)
          end
          sleep(wait)
        end
      end

      # Try to take n tokens without blocking
      #
      # @param n [Numeric] number of tokens to take
      # @return [Boolean] true if tokens were taken, false otherwise
      def try_take(n = 1)
        @mutex.synchronize do
          refill
          if @tokens >= n
            @tokens -= n
            true
          else
            false
          end
        end
      end

      # Return the number of currently available tokens
      #
      # @return [Float] available tokens
      def available
        @mutex.synchronize do
          refill
          @tokens
        end
      end

      # Calculate how long to wait for n tokens to become available
      #
      # @param n [Numeric] number of tokens needed
      # @return [Float] seconds to wait (0.0 if tokens are already available)
      def wait_time(n = 1)
        @mutex.synchronize do
          refill
          compute_wait_time(n)
        end
      end

      # Drain all tokens from the bucket
      #
      # @return [self]
      def drain
        @mutex.synchronize do
          @tokens = 0.0
        end
        self
      end

      # Reset the bucket to full capacity
      #
      # @return [self]
      def reset
        @mutex.synchronize do
          @tokens = @capacity
          @last_refill = now
        end
        self
      end

      # Check whether the bucket is at full capacity
      #
      # @return [Boolean]
      def full?
        @mutex.synchronize do
          refill
          @tokens >= @capacity
        end
      end

      private

      def compute_wait_time(n)
        deficit = n - @tokens
        return 0.0 if deficit <= 0

        deficit / @refill_rate
      end

      def refill
        current = now
        elapsed = current - @last_refill

        case @strategy
        when :smooth
          @tokens = [@tokens + (elapsed * @refill_rate), @capacity].min
        when :interval
          intervals = (elapsed / @refill_interval).floor
          if intervals >= 1
            @tokens = @capacity
            @last_refill += intervals * @refill_interval
            return
          end
        end

        @last_refill = current
      end

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
