# frozen_string_literal: true

module Middleware
  # Rack 2.2.19+ raises EOFError from the multipart parser when requests
  # exceed the new buffering limits (preamble, per-part headers, or total
  # buffered upload size). Puma's client_error handler silently swallows
  # EOFError — treating it as a normal client disconnect — and closes the
  # connection without sending any HTTP response. From HAProxy's perspective
  # this looks like a bad gateway (502), even on unrelated subsequent
  # requests sharing the same keep-alive connection.
  #
  # This middleware intercepts EOFError raised during request processing and
  # returns a proper 400 response so Puma can close the connection cleanly.
  #
  # The three rack 2.2.19 limits and their EOFError messages:
  #   "multipart boundary not found within limit" — preamble before first boundary exceeds 16KB (hard-coded)
  #   "multipart mime part header too large"      — a single MIME part header exceeds 64KB (hard-coded)
  #   "multipart data over retained size limit"   — total non-file field data exceeds 16MB
  #                                                 (configurable via RACK_MULTIPART_BUFFERED_UPLOAD_BYTESIZE_LIMIT)
  class MultipartEofHandler
    def initialize(app)
      @app = app
    end

    def call(env)
      Rails.logger.debug { "MultipartEofHandler: enter #{env['REQUEST_METHOD']} #{env['PATH_INFO']}" }
      @app.call(env)
    rescue EOFError => e
      content_length = env['CONTENT_LENGTH'] || 'unknown'
      content_type   = env['CONTENT_TYPE'] || 'unknown'
      Rails.logger.warn(
        "MultipartEofHandler: caught EOFError (#{e.message}) for " \
        "#{env['REQUEST_METHOD']} #{env['PATH_INFO']} " \
        "Content-Length: #{content_length} Content-Type: #{content_type}"
      )
      [400, { "Content-Type" => "text/plain", "Content-Length" => "11" }, ["Bad Request"]]
    end
  end
end
