# frozen_string_literal: true

class Anonymous
  include Actorable

  attr_reader :request_attributes

  def initialize(request_attributes)
    @request_attributes = request_attributes
  end

  def email
    nil
  end

  def agent_type
    :Anonymous
  end

  def agent_id
    :any
  end

  def platform_admin?
    false
  end

  def developer?
    false
  end

  def role?
    false
  end

  def roles
    Role.where(resource_type: 'None') # Empty result set
  end

  def press_role?
    false
  end

  def presses
    []
  end

  def admin_presses
    []
  end

  def editor_presses
    []
  end

  def analyst_presses
    []
  end
end
