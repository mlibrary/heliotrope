# frozen_string_literal: true

require 'ostruct'

module Authority
  class << self
    delegate :permits?, :grant!, :revoke!, :which, :who, :what, to: :authority

    # Agent

    def agent_grants?(agent)
      authority.which(agent, :read).any?
    end

    def agent(agent_type, agent_id) # rubocop:disable Metrics/CyclomaticComplexity
      raise ArgumentError unless ValidationService.valid_agent_type?(agent_type)
      return OpenStruct.new(agent_type: agent_type, agent_id: agent_id) if agent_id&.to_s == 'any'
      raise ArgumentError unless ValidationService.valid_agent?(agent_type, agent_id)
      case agent_type&.to_s&.to_sym
      when :Guest
        User.guest(user_key: agent_id)
      when :Individual
        Individual.find(agent_id)
      when :Institution
        Institution.find(agent_id)
      when :User
        User.find(agent_id)
      else
        OpenStruct.new(agent_type: agent_type, agent_id: agent_id)
      end
    end

    # Credential

    def credential_grants?(credential)
      authority.who(credential, Checkpoint::Resource.all).any?
    end

    def permission(permission)
      raise ArgumentError unless ValidationService.valid_permission?(permission)
      Checkpoint::Credential::Permission.new(permission)
    end

    def credential(credential_type, credential_id)
      raise ArgumentError unless ValidationService.valid_credential?(credential_type, credential_id)
      case credential_type&.to_sym
      when :permission
        permission(credential_id)
      else
        OpenStruct.new(credential_type: credential_type, credential_id: credential_id)
      end
    end

    # Resource

    def resource_grants?(resource)
      authority.who(:read, resource).any?
    end

    def resource(resource_type, resource_id) # rubocop:disable Metrics/CyclomaticComplexity
      raise ArgumentError unless ValidationService.valid_resource_type?(resource_type)
      return OpenStruct.new(resource_type: resource_type, resource_id: resource_id) if resource_id&.to_s == 'any'
      raise ArgumentError unless ValidationService.valid_resource?(resource_type, resource_id)
      case resource_type&.to_s&.to_sym
      when :ElectronicPublication
        Sighrax.factory(resource_id)
      when :Component
        Component.find(resource_id)
      when :Product
        Product.find(resource_id)
      else
        OpenStruct.new(resource_type: resource_type, resource_id: resource_id)
      end
    end

    private

      def authority
        Services.checkpoint
      end
  end
end
