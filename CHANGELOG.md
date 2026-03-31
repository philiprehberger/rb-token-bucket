# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-03-31

### Added
- Configurable refill strategy with `strategy:` parameter (`:smooth` default, `:interval` for burst refill)
- `#drain` method to empty all tokens
- `#full?` predicate to check if bucket is at capacity
- GitHub issue templates, PR template, and Dependabot configuration
- Portfolio homepage in gemspec metadata

### Changed
- README restructured with all 8 standard badges and Support section

## [0.1.5] - 2026-03-24

### Changed
- Expand README API table to document all public methods

## [0.1.4] - 2026-03-24

### Fixed
- Standardize README code examples to use double-quote require statements

## [0.1.3] - 2026-03-24

### Fixed
- Fix Installation section quote style to double quotes

## [0.1.2] - 2026-03-22

### Changed
- Expanded test suite to 30+ examples covering edge cases, error paths, and boundary conditions

## [0.1.1] - 2026-03-22

### Changed
- Version bump for republishing

## [0.1.0] - 2026-03-22

### Added
- Initial release
- Token bucket rate limiter with configurable capacity and refill rate
- Blocking take and non-blocking try_take methods
- Available token count and wait time estimation
- Thread-safe implementation with Mutex
