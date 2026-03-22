# frozen_string_literal: true

require_relative 'lib/philiprehberger/token_bucket/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-token_bucket'
  spec.version       = Philiprehberger::TokenBucket::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'Token bucket rate limiter with configurable capacity and refill rate'
  spec.description   = 'Thread-safe token bucket rate limiter with configurable capacity and refill rate, ' \
                       'supporting blocking and non-blocking token acquisition.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-token-bucket'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
