module RolesHelper
  # Format the available roles for a select_tag
  def roles_for_select
    Role::ROLES.each_with_object({}) do |key, object|
      object[t("role.#{key}")] = key
    end
  end
end
