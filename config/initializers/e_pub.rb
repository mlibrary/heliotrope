# frozen_string_literal: true

# Use this setup block to configure all options available in EPub.
# NOTE: `EPub` lives in `lib` and is autoloaded, and since Rails 7 the main
# Zeitwerk autoloader is only set up *after* `config/initializers` are loaded.
# Configuration that references autoloaded constants must therefore happen in a
# `to_prepare` block.
Rails.application.config.to_prepare do
  EPub.configure do |config|
    config.logger = Rails.logger
  end
end
