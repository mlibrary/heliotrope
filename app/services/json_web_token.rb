# frozen_string_literal: true

module JsonWebToken
  # secret to encode and decode token
  HMAC_SECRET = Rails.application.secrets.secret_key_base

  # https://github.com/jwt/ruby-jwt
  #
  # JSON Web Token defines some reserved claim names
  # and defines how they should be used.
  #
  # JWT supports these reserved claim names:
  #
  # 'exp' (Expiration Time) Claim
  # 'nbf' (Not Before Time) Claim
  # 'iss' (Issuer) Claim
  # 'aud' (Audience) Claim
  # 'jti' (JWT ID) Claim
  # 'iat' (Issued At) Claim
  # 'sub' (Subject) Claim
  #
  # Ruby-jwt gem supports custom header fields
  # To add custom header fields you need to pass header_fields parameter
  #
  # expires = Time.now.to_i
  # payload = { data: 'test', exp: expires }
  #
  # token = JWT.encode payload, HMAC_SECRET, algorithm='HS256', header_fields={ typ: 'JWT' }
  #
  # leeway = 30 # seconds
  #
  # puts JWT.decode token, hmac_secret, true, { exp_leeway: leeway, algorithm: 'HS256' }
  #
  # [
  #   {"data"=>"test", "exp"=>expires }, # payload
  #   {"typ"=>"JWT", "alg"=>"HS256" } # header
  # ]

  def self.encode(payload)
    JWT.encode(payload, HMAC_SECRET, 'HS256')
  end

  def self.decode(token)
    HashWithIndifferentAccess.new JWT.decode(token, HMAC_SECRET, true, algorithm: 'HS256')[0]
  end
end
