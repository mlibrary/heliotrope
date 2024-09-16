# frozen_string_literal: true

class ScholarlyiqRedirectUrlService
  def self.encrypted_url(config, institutions)
    yaml = YAML.safe_load(File.read(config))
    url = yaml["siq_portal_url"]
    secret = yaml["siq_shared_secret"] # AES-128-GCM requires a 16-byte key
    iv = SecureRandom.random_bytes(12) # AES-128-GCM require a 12 byte nonce

    cipher = OpenSSL::Cipher.new("aes-128-gcm")
    cipher.encrypt
    cipher.key = secret
    cipher.iv = iv

    payload = {}
    payload["siteIds"] = []
    institutions.each do |inst|
      payload["siteIds"] << inst.identifier
    end

    encrypted_payload = cipher.update(payload.to_json) + cipher.final
    auth_tag = cipher.auth_tag

    encoded_encrypted_payload = Base64.strict_encode64(encrypted_payload + auth_tag)
    encoded_nonce = Base64.strict_encode64(iv)

    url_encoded_encrypted_payload = CGI.escape(encoded_encrypted_payload)
    url_encoded_nonce = CGI.escape(encoded_nonce)

    token = "#{url_encoded_nonce}:#{url_encoded_encrypted_payload}"
    url + "?token=#{token}"
  end
end
