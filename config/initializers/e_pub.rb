# frozen_string_literal: true

require Rails.root.join('lib', 'e_pub').to_s

# Use this setup block to configure all options available in EPub.
EPub.configure do |config|
  config.logger = Rails.logger
end
