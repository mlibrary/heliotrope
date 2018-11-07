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

  def agent_type
    :Anonymous
  end

  def agent_id
    :any
  end
end
