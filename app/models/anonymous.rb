# frozen_string_literal: true

class Anonymous
  attr_reader :request_attributes

  def initialize(request_attributes)
    @request_attributes = request_attributes
  end

  def email
    nil
  end

  def individual
    nil
  end

  def institutions
    Services.dlps_institution.find(request_attributes)
  end

  def affiliations(institution)
    Services.dlps_institution_affiliation.find(request_attributes).select { |ia| ia.institution_id == institution.id }
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
