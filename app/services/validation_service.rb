# frozen_string_literal: true

require 'ostruct'

class ValidationService
  # Class Methods

  # Syntax Validation a.k.a. Regular Expression Match? and such

  def self.valid_email?(email)
    /^[^@]+@[^@]+\.+[^@|\.]+$/.match?(email&.to_s)
  end

  def self.valid_id?(id)
    !!id&.to_i&.positive? # rubocop:disable Style/DoubleNegation
  end

  def self.valid_noid?(noid)
    /^[[:alnum:]]{9}$/.match?(noid)
  end

  # Object Validation

  def self.valid_entity?(id)
    valid_noid?(id) && Sighrax.factory(id).valid?
  end

  def self.valid_component?(id)
    valid_id?(id) && Component.find(id).present?
  end

  def self.valid_individual?(id)
    valid_id?(id) && Individual.find(id).present?
  end

  def self.valid_institution?(id)
    valid_id?(id) && Institution.find(id).present?
  end

  def self.valid_product?(id)
    valid_id?(id) && Product.find(id).present?
  end

  def self.valid_user?(id)
    valid_id?(id) && User.find(id).present?
  end

  # Agent Validation

  def self.valid_agent_type?(type)
    %i[any Guest Individual Institution User].include?(type&.to_s&.to_sym)
  end

  def self.valid_agent?(agent_type, agent_id) # rubocop:disable  Metrics/CyclomaticComplexity
    any_id = agent_id&.to_s&.to_sym == :any
    case agent_type&.to_s&.to_sym
    when :any
      any_id
    when :Guest
      any_id || valid_email?(agent_id)
    when :Individual
      any_id || valid_individual?(agent_id)
    when :Institution
      any_id || valid_institution?(agent_id)
    when :User
      any_id || valid_user?(agent_id)
    else
      false
    end
  end

  # Permission Credential Validation

  def self.valid_permission?(permission)
    %i[any read].include?(permission&.to_s&.to_sym)
  end

  # Credential Validation

  def self.valid_credential_type?(type)
    %i[permission].include?(type&.to_s&.to_sym)
  end

  def self.valid_credential?(credential_type, credential_id)
    any_id = credential_id&.to_s&.to_sym == :any
    case credential_type&.to_s&.to_sym
    # when :any
    #   any_id
    when :permission
      any_id || valid_permission?(credential_id)
    else
      false
    end
  end

  # Resource Validation

  def self.valid_resource_type?(type)
    %i[any ElectronicPublication Component Product].include?(type&.to_s&.to_sym)
  end

  def self.valid_resource?(resource_type, resource_id) # rubocop:disable  Metrics/CyclomaticComplexity
    any_id = resource_id&.to_s&.to_sym == :any
    case resource_type&.to_s&.to_sym
    when :any
      any_id
    when :ElectronicPublication
      any_id || valid_entity?(resource_id)
    when :Component
      any_id || valid_component?(resource_id)
    when :Product
      any_id || valid_product?(resource_id)
    else
      false
    end
  end

  # Actor Validation

  def self.valid_actor?(actor)
    return false if actor.blank?
    return true if actor.is_a?(Anonymous)
    return true if actor.is_a?(User)
    return true if actor.is_a?(Guest)
    false
  end
end
