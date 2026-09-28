# frozen_string_literal: true

require Rails.root.join('lib', 'pdf_ebook').to_s

# Use this setup block to configure all options available in PDFEbook.
PDFEbook.configure do |config|
  config.logger = Rails.logger
end
