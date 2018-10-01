# frozen_string_literal: true

class PolicyAgent
  def initialize(agent_class, agent)
    @agent_class = agent_class
    @agent = agent
  end

  def agent_type
    @agent_class.name.downcase
  end

  def type
    agent_type
  end

  def agent_id
    @agent.id
  end

  def id
    agent_id
  end

  def token
    Checkpoint::Agent::Token.new(type, id)
  end

  def identity
    { agent_type => agent_id }
  end

  def entity
    @agent || @agent_class
  end
end
