# frozen_string_literal: true

module RolesHelper
  # Format the available roles for a select_tag
  def roles_for_select
    Role::ROLES.index_by do |key|
      t("role.#{key}")
    end
  end
end
