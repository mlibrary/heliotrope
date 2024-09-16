# frozen_string_literal: true

# Add fulcrum specific flipflop features here

Flipflop.configure do
  feature :scholarlyiq_counter_redirect,
          default: false,
          description: "Redirect known users from /counter_report to scholarlyiq"
end
