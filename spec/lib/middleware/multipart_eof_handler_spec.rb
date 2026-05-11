# frozen_string_literal: true

require 'rails_helper'
require 'middleware/multipart_eof_handler'

# HELIO-4994, HELIO-4989
# Rack 2.2.19+ raises EOFError from the multipart parser for oversized
# requests. Puma's client_error handler silently swallows EOFError — treating it as a normal client disconnect — and closes the connection without sending any HTTP response. From HAProxy's perspective this looks like a bad gateway (502), even on unrelated subsequent requests sharing the same keep-alive connection.
#
# This middleware intercepts EOFError raised during request processing and returns a proper 400 response so Puma can close the connection cleanly.
RSpec.describe Middleware::MultipartEofHandler do
  let(:app) { double('app') }
  let(:middleware) { described_class.new(app) }
  let(:env) { Rack::MockRequest.env_for('/') }

  before do
    allow(Rails.logger).to receive(:warn)
  end

  context 'when the downstream app returns normally' do
    it 'passes the response through unchanged' do
      allow(app).to receive(:call).with(env).and_return([200, {}, ['OK']])
      status, _headers, body = middleware.call(env)
      expect(status).to eq(200)
      expect(body).to eq(['OK'])
    end

    it 'logs a debug entry for every request' do
      allow(app).to receive(:call).and_return([200, {}, ['OK']])
      expect(Rails.logger).to receive(:debug) do |&block|
        expect(block.call).to match(/MultipartEofHandler: enter GET \//)
      end
      middleware.call(env)
    end
  end

  context 'when the downstream app raises EOFError' do
    it 'returns a 400 Bad Request response instead of propagating the error' do
      allow(app).to receive(:call).and_raise(EOFError, 'multipart boundary not found within limit')
      allow(Rails.logger).to receive(:warn)
      status, headers, body = middleware.call(env)
      expect(status).to eq(400)
      expect(headers['Content-Type']).to eq('text/plain')
      expect(body).to eq(['Bad Request'])
    end

    it 'does not re-raise the EOFError' do
      allow(app).to receive(:call).and_raise(EOFError)
      allow(Rails.logger).to receive(:warn)
      expect { middleware.call(env) }.not_to raise_error
    end

    it 'logs a warning with the request method, path, and error message' do
      allow(app).to receive(:call).and_raise(EOFError, 'multipart boundary not found within limit')
      expect(Rails.logger).to receive(:warn).with(a_string_matching(/MultipartEofHandler.*multipart boundary not found within limit.*GET.*\//))
      middleware.call(env)
    end

    it 'logs Content-Length and Content-Type from the request' do
      env['CONTENT_LENGTH'] = '1048576'
      env['CONTENT_TYPE'] = 'multipart/form-data; boundary=abc123'
      allow(app).to receive(:call).and_raise(EOFError, 'multipart boundary not found within limit')
      expect(Rails.logger).to receive(:warn).with(a_string_matching(/Content-Length: 1048576.*Content-Type: multipart\/form-data/))
      middleware.call(env)
    end
  end

  context 'when the downstream app raises a different error' do
    it 'does not swallow non-EOFError exceptions' do
      allow(app).to receive(:call).and_raise(RuntimeError, 'something else')
      expect { middleware.call(env) }.to raise_error(RuntimeError, 'something else')
    end
  end
end
