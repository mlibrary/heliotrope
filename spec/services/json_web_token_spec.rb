# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JsonWebToken do
  let(:payload) { { email: email } }
  let(:email) { 'user@example.com' }

  it 'encodes and decodes' do
    token = described_class.encode(payload)
    expect(token.split('.').count).to eq(3)
    decoded_payload = described_class.decode(token)
    expect(decoded_payload[:email]).to eq(email)
  end
end
