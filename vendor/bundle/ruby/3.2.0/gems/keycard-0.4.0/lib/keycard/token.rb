# frozen_string_literal: true

# Holds utility methods for parsing tokens from header values
class Keycard::Token
  TOKEN_DELIMS = /\s*[:,;\t]\s*/

  class << self
    def rfc7235(string)
      string
        .sub(/^(Bearer|Token):?/, "")
        .split(TOKEN_DELIMS)
        .map { |assignment| split_assignment(assignment) }
        .to_h["token"]
    end

    private

    # @param string_assignment [String] of the form 'key="value"'
    # @return An array of pairs of key:value, both strings
    def split_assignment(string_assignment)
      clean_assignment(string_assignment)
        .split("=")
        .push("")
        .slice(0, 2)
    end

    # @param string_assignment [String] of the form 'key="value"'
    # @return [String] With the quotes and extraneous whitespace removed.
    def clean_assignment(string_assignment)
      string_assignment
        .delete('"')
        .strip
    end
  end
end
