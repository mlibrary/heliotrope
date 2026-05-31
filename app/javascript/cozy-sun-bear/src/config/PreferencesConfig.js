/**
 * Shared configuration for user preferences
 * Contains valid values for all preference options
 */

export const PreferencesConfig = {
  // Font options
  fonts: {
    valid: [
      'default',
      'Palatino,Palatino Linotype,Palatino LT STD,Book Antiqua,Georgia,serif',
      'TimesNewRoman,Times New Roman,Times,Baskerville,Georgia,serif',
      'Arial,Helvetica Neue,Helvetica,sans-serif',
      'Verdana,Geneva,sans-serif',
      'OpenDyslexic',
      'Consolas,monaco,monospace'
    ],
    default: 'default'
  },

  // Text size values (50% to 400% in 10% increments)
  textSize: {
    valid: (() => {
      const values = [];
      for (let i = 50; i <= 400; i += 10) {
        values.push(i);
      }
      return values;
    })(),
    default: 100,
    min: 50,
    max: 400
  },

  // Scale values for pre-paginated layouts (50% to 400% in 10% increments)
  scale: {
    valid: (() => {
      const values = [];
      for (let i = 50; i <= 400; i += 10) {
        values.push(i);
      }
      return values;
    })(),
    default: 100,
    min: 50,
    max: 400
  },

  // Word spacing values
  wordSpacing: {
    valid: ['auto', '.0675rem', '.125rem', '.1875rem', '.25rem', '.3125rem', '.375rem', '.4375rem', '.5rem', '1rem'],
    default: 'auto'
  },

  // Letter spacing values
  letterSpacing: {
    valid: ['auto', '.0675rem', '.125rem', '.1875rem', '.25rem', '.3125rem', '.375rem', '.4375rem', '.5rem'],
    default: 'auto'
  },

  // Line height values
  lineHeight: {
    valid: ['auto', '1', '1.125', '1.25', '1.35', '1.5', '1.65', '1.75', '2'],
    default: 'auto'
  },

  // Margins values
  margins: {
    valid: ['auto', '.5rem', '.75rem', '1rem', '1.25rem', '1.5rem', '1.75rem', '2rem'],
    default: 'auto'
  },

  // Paragraph spacing values
  paragraphSpacing: {
    valid: ['auto', '.5rem', '1rem', '1.25rem', '1.5rem', '2rem', '2.5rem', '3rem'],
    default: 'auto'
  },

  // Flow/display mode values
  flow: {
    valid: ['auto', 'paginated', 'scrolled-doc'],
    default: 'auto'
  },

  // Theme values (default only - custom themes added dynamically)
  theme: {
    valid: ['default'],
    default: 'default'
  }
};

/**
 * Sanitize a preference value by checking if it's valid
 * @param {string} preference - The preference type (e.g., 'fonts', 'textSize', 'wordSpacing')
 * @param {*} value - The value to sanitize
 * @returns {*} - The sanitized value (valid value or default)
 */
export function sanitizePreference(preference, value) {
  var config = PreferencesConfig[preference];

  if (!config) {
    console.warn('Unknown preference type: ' + preference);
    return value;
  }

  // Handle numeric values (textSize, scale)
  if (preference === 'textSize' || preference === 'scale') {
    if (value === null || value === undefined) {
      return config.default;
    }
    var numValue = typeof value === 'string' ? parseInt(value, 10) : value;

    // Check if it's a valid number
    if (isNaN(numValue)) {
      return config.default;
    }

    // Return immediately if already an explicitly valid value
    if (config.valid.includes(numValue)) {
      return numValue;
    }

    // Clamp to min/max range and then snap to nearest valid step
    var validNumericValues = config.valid.filter(function(v) { return typeof v === 'number'; });
    if (validNumericValues.length === 0) {
      return config.default;
    }

    var normalizedValue = numValue;
    if (config.min !== undefined && config.max !== undefined) {
      normalizedValue = Math.max(config.min, Math.min(config.max, numValue));
    }

    return validNumericValues.reduce(function(closest, current) {
      return Math.abs(current - normalizedValue) < Math.abs(closest - normalizedValue) ? current : closest;
    });
  }

  // Handle string values (all other preferences) - strict whitelist only
  var stringValue = String(value);

  if (config.valid.includes(stringValue)) {
    return stringValue;
  }

  console.warn('Invalid value for ' + preference + ': ' + value + ', using default: ' + config.default);
  return config.default;
}

/**
 * Sanitize multiple preferences at once
 * @param {Object} preferences - Object containing preference key-value pairs
 * @returns {Object} - Sanitized preferences object
 */
export function sanitizePreferences(preferences) {
  if (!preferences || typeof preferences !== 'object') {
    return {};
  }

  // Use Object.create(null) to avoid prototype pollution from user-controlled keys
  var sanitized = Object.create(null);

  var keyMap = {
    'font': 'fonts',
    'text_size': 'textSize',
    'word_spacing': 'wordSpacing',
    'letter_spacing': 'letterSpacing',
    'line_height': 'lineHeight',
    'paragraph_spacing': 'paragraphSpacing'
  };

  // Skip keys that could trigger prototype mutation
  var dangerousKeys = ['__proto__', 'constructor', 'prototype'];

  var keys = Object.keys(preferences);
  for (var i = 0; i < keys.length; i++) {
    var key = keys[i];
    if (dangerousKeys.indexOf(key) !== -1) { continue; }
    var value = preferences[key];
    var configKey = keyMap[key] || key;

    if (PreferencesConfig[configKey]) {
      sanitized[key] = sanitizePreference(configKey, value);
    } else {
      // Pass through values that don't have config (e.g., rootfilePath)
      sanitized[key] = value;
    }
  }

  return sanitized;
}

