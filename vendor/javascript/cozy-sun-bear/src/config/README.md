# Preferences Configuration and Sanitization

This directory contains the shared configuration for user preferences and input sanitization.

## Overview

The `PreferencesConfig.js` file provides:

1. **Centralized Configuration**: All valid values for user preferences in one location
2. **Input Sanitization**: Functions to validate and sanitize user inputs before they're applied
3. **Default Values**: Safe defaults for all preference types

## Configuration Structure

### PreferencesConfig

Contains configuration for all user preference options:

- **fonts**: Valid font families and stacks
- **textSize**: Font size percentages (50% to 400% in 10% increments)
- **scale**: Scale values for pre-paginated layouts (50% to 400% in 10% increments)
- **wordSpacing**: Valid CSS word-spacing values
- **letterSpacing**: Valid CSS letter-spacing values
- **lineHeight**: Valid CSS line-height values
- **margins**: Valid CSS margin values
- **paragraphSpacing**: Valid CSS paragraph spacing values
- **flow**: Display modes (auto, paginated, scrolled-doc)
- **theme**: Available themes

Each configuration object contains:
- `valid`: Array of valid values
- `default`: The default value
- `min`/`max` (for numeric values): Minimum and maximum allowed values

## Sanitization Functions

### sanitizePreference(preference, value)

Validates a single preference value against the configuration.

**Parameters:**
- `preference` (string): The preference type (e.g., 'textSize', 'fonts', 'wordSpacing')
- `value` (any): The value to sanitize

**Returns:**
- The validated value if it's in the valid list
- The clamped value if numeric and within min/max range
- The default value if invalid

**Example:**
```javascript
import { sanitizePreference } from '../config/PreferencesConfig';

const fontSize = sanitizePreference('textSize', 150); // Returns 150
const invalidSize = sanitizePreference('textSize', 9999); // Returns 400 (clamped to max)
const badValue = sanitizePreference('wordSpacing', 'invalid'); // Returns 'auto' (default)
```

### sanitizePreferences(preferences)

Sanitizes multiple preferences at once.

**Parameters:**
- `preferences` (object): Object containing preference key-value pairs

**Returns:**
- Object with all values sanitized

**Example:**
```javascript
import { sanitizePreferences } from '../config/PreferencesConfig';

const userPrefs = {
  font: 'Arial,Helvetica Neue,Helvetica,sans-serif',
  text_size: 120,
  word_spacing: '.125rem',
  invalid_key: 'some value'
};

const sanitized = sanitizePreferences(userPrefs);
// Returns sanitized values, passes through unknown keys
```

## Usage in the Codebase

### Control.Preferences.js

The preferences UI uses `PreferencesConfig` to:
- Define slider ranges and valid values
- Initialize form controls with valid options
- Ensure user selections are within valid ranges

### Reader.EpubJS.js

The reader sanitizes preferences:
- When loading stored preferences from `_cozyOptions`
- In the `reopen()` method before applying new preferences
- In the prehooks before injecting CSS styles
- When updating scale values

## Security Considerations

The sanitization system protects against:

1. **Invalid CSS injection**: Only valid, predefined CSS values are allowed
2. **Out-of-range values**: Numeric values are snapped to the nearest valid discrete step within the allowed range
3. **Unexpected or malicious string input**: String-based preferences such as fonts must match predefined allowed values, so inputs like `<script>` or `javascript:` are rejected because they are not on the allowlist
4. **Type coercion issues**: Values are properly typed and validated
5. **Prototype pollution**: Dangerous keys (`__proto__`, `constructor`, `prototype`) are skipped and the result object is created with `Object.create(null)`

## Adding New Preferences

To add a new preference:

1. Add configuration to `PreferencesConfig`:
```javascript
newPreference: {
  valid: ['value1', 'value2', 'value3'],
  default: 'value1'
}
```

2. Update the key mapping in `sanitizePreferences()` if needed

3. Use the sanitized values in your code:
```javascript
const value = sanitizePreference('newPreference', userInput);
```

## Testing

When testing preferences:
- Test with valid values from the `valid` array
- Test with out-of-range numeric values to ensure clamping works
- Test with invalid strings to ensure defaults are used
- Test with potentially malicious input (scripts, HTML tags)

