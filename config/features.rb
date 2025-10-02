# frozen_string_literal: true

# Add fulcrum specific flipflop features here

Flipflop.configure do
  feature :scholarlyiq_counter_redirect,
          default: false,
          description: "Redirect known users from /counter_report to scholarlyiq"
  feature :no_able_player_for_youtube_videos,
          default: false,
          description: "YouTube videos will never use Able Player"
  feature :show_accessibility_claims_tab,
          default: false,
          description: "The 'Accessibility Claims' tab will appear on Monograph catalog pages"
  feature :use_shib_security_domain_logic,
          default: false,
          description: "Use security_domain logic for Shibboleth institution matching (HELIO-4961)"
end
