# frozen_string_literal: true

class Grant
  include ActiveModel::Model

  attr_accessor :agent_type
  attr_accessor :agent_id, :agent_user_id, :agent_individual_id, :agent_institution_id
  attr_accessor :credential_type
  attr_accessor :credential_id, :credential_permission_id
  attr_accessor :resource_type
  attr_accessor :resource_id, :resource_noid_id, :resource_component_id, :resource_product_id
end
