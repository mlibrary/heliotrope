# Config Tests

This directory contains tests for the configuration and sanitization functionality.

## Files

### PreferencesConfigSpec.js

Tests for the `PreferencesConfig` module, including:

- **Valid Values Configuration**: Tests that the configuration contains expected valid values
- **sanitizePreference()**: Tests for single preference sanitization
  - Valid value handling
  - Out-of-range value clamping
  - Invalid value defaults
  - Type conversion (string to number)
  - Security checks (script injection, XSS attempts)
- **sanitizePreferences()**: Tests for batch preference sanitization
  - Multiple preference handling
  - Mixed valid/invalid values
  - Pass-through of unknown keys
- **Security Tests**: Tests for injection attack prevention
  - XSS attempts in font fields
  - CSS injection attempts in spacing fields
- **Edge Cases**: Tests for null, undefined, and empty string handling

## Running Tests

The tests are integrated into the Karma test suite:

```bash
npm test
```

## Test Status

✅ These tests are active and run as part of the Karma test suite.

`PreferencesConfigSpec.js` verifies the exported `PreferencesConfig` module and its sanitization behavior in the current test environment. The module is exposed through the `cozy` global namespace (via `src/config/index.js`) so tests can access `cozy.PreferencesConfig`, `cozy.sanitizePreference`, and `cozy.sanitizePreferences`.

## Future Work

- [ ] Add integration tests with Control.Preferences
- [ ] Add integration tests with Reader.EpubJS
- [ ] Add performance tests for bulk sanitization

