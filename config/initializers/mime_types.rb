# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
Mime::Type.register "application/n-triples", :nt
Mime::Type.register "application/ld+json", :jsonld
Mime::Type.register "text/turtle", :ttl
Mime::Type.register 'application/x-endnote-refer', :endnote
Mime::Type.register "application/pdf", :pdf

# Ensure .mjs (ES module) files are served with the correct MIME type.
# Without this, browsers reject them with a strict MIME type error when
# loaded via <script type="module"> (e.g. pdf.js 6.x viewer.mjs).
# (and, no, this doesn't work: Mime::Type.register "application/javascript", :mjs)
Rack::Mime::MIME_TYPES['.mjs'] = 'application/javascript'
