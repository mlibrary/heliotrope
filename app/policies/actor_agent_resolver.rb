# frozen_string_literal: true

require 'checkpoint/agent'
require 'ostruct'

# This resolver depends on the actor being a hash { email: email, institutions: [institutions] },
# from which key values are extracted and delivered as agents,
# as converted by the `agent_factory`.
class ActorAgentResolver < Checkpoint::Agent::Resolver
  def initialize(agent_factory: Checkpoint::Agent)
    @agent_factory = agent_factory
  end

  def resolve(actor)
    agents = []
    agents << agent_factory.from(OpenStruct.new(agent_type: :email, agent_id: actor[:email].downcase)) if actor[:email].present?
    actor[:institutions].map do |institution|
      agents << agent_factory.from(OpenStruct.new(agent_type: :institution, agent_id: institution.identifier))
    end
    agents
  end

  private

    attr_reader :agent_factory
end
