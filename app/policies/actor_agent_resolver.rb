# frozen_string_literal: true

require 'checkpoint/agent'
require 'ostruct'

# This resolver depends on the actor being a hash { user: current_user, institutions: [current_institutions] },
# from which key values are extracted and delivered as agents,
# as converted by the `agent_factory`.
class ActorAgentResolver < Checkpoint::Agent::Resolver
  def initialize(agent_factory: Checkpoint::Agent)
    @agent_factory = agent_factory
  end

  def resolve(actor)
    agents = []
    agents << agent_factory.from(OpenStruct.new(agent_type: :any, agent_id: :any)) # All actors
    current_user = actor[:user]
    if current_user.present?
      email = current_user.email&.downcase
      if email.present?
        user = User.find_by(email: email)
        agents << agent_factory.from(user) if user.present?
        individual = Individual.find_by(email: email)
        agents << agent_factory.from(individual) if individual.present?
      end
    end
    (actor[:institutions] || []).map do |institution|
      agents << agent_factory.from(institution)
    end
    agents
  end

  private

    attr_reader :agent_factory
end
