# frozen_string_literal: true

class PolicyCredential
  def initialize(credential_class, credential)
    @credential_class = credential_class
    @credential = credential
  end

  def credential_type
    @credential_class.to_s.downcase
  end

  def type
    credential_type
  end

  def credential_id
    @credential.to_s
  end

  def id
    credential_id
  end

  def token
    Checkpoint::Credential::Token.new(type, id)
  end

  def identity
    { credential_type => credential_id }
  end

  def entity
    @credential || @credential_class
  end
end
