# frozen_string_literal: true

require_relative 'token_bucket/version'

module Philiprehberger
  module TokenBucket
    class Error < StandardError; end

    # A thread-safe token bucket rate limiter
    class Bucket
      # @param capacity [Numeric] maximum number of tokens
      # @param refill_rate [Numeric] tokens added per second
      def initialize(capacity:, refill_rate:)
        raise Error, 'capacity must be positive' unless capacity.positive?
        raise Error, 'refill_rate must be positive' unless refill_rate.positive?

        @capacity = capacity.to_f
        @refill_rate = refill_rate.to_f
        @tokens = @capacity
        @last_refill = now
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

      private

      def compute_wait_time(n)
        deficit = n - @tokens
        return 0.0 if deficit <= 0

        deficit / @refill_rate
      end

      def refill
        current = now
        elapsed = current - @last_refill
        @tokens = [@tokens + elapsed * @refill_rate, @capacity].min
        @last_refill = current
      end

      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
