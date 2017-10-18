# frozen_string_literal: true

# Use this setup block to configure all options available in EPub.
EPub.configure do |config|
  config.logger = Rails.logger
  config.root = Rails.root.join('tmp', 'epubs')
end
