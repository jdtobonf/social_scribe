# HubSpot Integration Tests

This directory contains unit tests for the HubSpot integration modules.

## Test Files

### 1. `oauth_test.exs`
Tests for `Ueberauth.Strategy.Hubspot.OAuth` module.

**Coverage:**
- OAuth2 client configuration
- Authorization URL generation
- Access token retrieval
- Error handling for missing configuration
- OAuth2 strategy callbacks

### 2. `strategy_test.exs`
Tests for `Ueberauth.Strategy.Hubspot` module.

**Coverage:**
- Authentication request handling
- OAuth callback processing
- User data extraction (uid, credentials, info, extra)
- Session cleanup
- Error handling for missing authorization codes

### 3. `hubspot_test.exs` (in parent directory)
Tests for `SocialScribe.HubSpot` module.

**Coverage:**
- Tesla client configuration
- Token refresh logic (integration test - skipped in unit tests)
- Contact fetching (integration test - skipped in unit tests)
- Contact updates (integration test - skipped in unit tests)

## Running Tests

Run all HubSpot tests:
```bash
mix test test/social_scribe/hubspot
```

Run specific test file:
```bash
mix test test/social_scribe/hubspot/oauth_test.exs
mix test test/social_scribe/hubspot/strategy_test.exs
mix test test/social_scribe/hubspot_test.exs
```

Run with coverage:
```bash
mix test --cover test/social_scribe/hubspot
```

## Notes

- Some tests in `hubspot_test.exs` are marked with `@tag :skip` because they require HTTP mocking
- These skipped tests should be implemented as integration tests with proper HTTP mocking setup
- OAuth and Strategy tests are pure unit tests that don't require external dependencies
- All tests use the test database with Ecto.Adapters.SQL.Sandbox for isolation

## Future Improvements

1. Add integration tests with Tesla.Mock or similar HTTP mocking library
2. Add property-based tests for data transformation logic
3. Add tests for edge cases in token expiration handling
4. Add performance tests for bulk contact operations
