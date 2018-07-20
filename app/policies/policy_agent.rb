# frozen_string_literal: true

class PolicyAgent
  def initialize(agent_class, agent)
    @agent_class = agent_class
    @agent = agent
  end

  def agent_type
    @agent_class.name.downcase
  end

  def agent_id
    @agent.id
  end

  def identity
    { agent_type => agent_id }
  end
end
