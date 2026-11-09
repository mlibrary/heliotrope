# frozen_string_literal: true

# `lib/metadata_fields.rb` defines top-level constants which don't match its
# file name, so it is ignored by the autoloader (see config/application.rb) and
# loaded explicitly here.
require Rails.root.join('lib', 'metadata_fields').to_s

# `EPub` and `Webgl` are autoloadable, but the Zeitwerk autoloader isn't set up
# until after the initializers have run, so load them in a `to_prepare` block.
Rails.application.config.to_prepare do
  EPub
  Webgl
end
