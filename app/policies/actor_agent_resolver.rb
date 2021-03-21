# frozen_string_literal: true

require 'checkpoint/agent'

class ActorAgentResolver < Checkpoint::Agent::Resolver
  def expand(actor)
    agents = super(actor) + individuals(actor) + institutions(actor)
    agents
  end

  def convert(actor)
    agent = super(actor)
    agent
  end

  private

    def individuals(actor)
      return [] if actor.try(:individual).blank?
      [convert(actor.individual)]
    end

    def institutions(actor)
      return [] unless actor.respond_to?(:institutions)
      world_institutions = Greensub::Institution.where(identifier: Settings.world_institution_identifier).to_a
      (actor.institutions + world_institutions).map { |institution| convert(institution) }
    end
end
