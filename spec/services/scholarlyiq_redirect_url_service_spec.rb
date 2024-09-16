# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScholarlyiqRedirectUrlService do
  describe "#encrypted_url" do
    let(:institutions) do
      [
        create(:institution, identifier: "1"),
        create(:institution, identifier: "10")
      ]
    end

    let(:shared_secret) { "0123456789123456" } # 16 byte shared secret
    let(:nonce) { "012345678912" } # 12 byte nonce
    let(:yaml) { { "siq_portal_url" => "http://test.scholarlyiq.com", "siq_shared_secret" => shared_secret } }
    let(:config) { double("config") }

    before do
      allow(File).to receive(:read).and_return(true)
      allow(YAML).to receive(:safe_load).and_return(yaml)
      allow(SecureRandom).to receive(:random_bytes).with(12).and_return(nonce)
    end

    it "correctly builds the encrypted url" do
      # Just a check that the payload we encrpyted decrypts correctly
      redirect_url = described_class.encrypted_url(config, institutions)

      # Extract the token from the URL
      token_param = redirect_url.match(/token=([^&]+)/)[1]

      # Split the token into nonce and encrypted payload parts
      url_encoded_nonce, url_encoded_encrypted_payload = token_param.split(':')

      # URL-decode and Base64 decode the nonce and the encrypted payload
      iv = Base64.decode64(CGI.unescape(url_encoded_nonce))
      encrypted_payload_with_auth_tag = Base64.decode64(CGI.unescape(url_encoded_encrypted_payload))

      # Extract the ciphertext and authentication tag
      auth_tag = encrypted_payload_with_auth_tag[-16..-1]
      encrypted_payload = encrypted_payload_with_auth_tag[0..-17]

      # Create a Cipher for AES-128-GCM decryption
      cipher = OpenSSL::Cipher.new('aes-128-gcm')
      cipher.decrypt
      cipher.key = shared_secret
      cipher.iv = iv # use the decoded 12-byte nonce
      cipher.auth_tag = auth_tag

      # Decrypt the payload
      decrypted_payload = cipher.update(encrypted_payload) + cipher.final

      expect(iv).to eq nonce
      expect(JSON.parse(decrypted_payload)).to eq({ "siteIds" => ["1", "10"] })
    end
  end
end
