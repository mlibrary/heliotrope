# frozen_string_literal: true

Flipflop.configure do
  # Strategies will be used in the order listed here.
  feature :search_snippets,
          default: false,
          description: "Show full text search snippets"
end
