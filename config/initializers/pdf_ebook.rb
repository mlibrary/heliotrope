# frozen_string_literal: true

# Use this setup block to configure all options available in PDFEbook.
# NOTE: see the comment in `config/initializers/e_pub.rb`; autoloaded constants
# can only be referenced once the Zeitwerk autoloader has been set up.
Rails.application.config.to_prepare do
  PDFEbook.configure do |config|
    config.logger = Rails.logger
  end
end
