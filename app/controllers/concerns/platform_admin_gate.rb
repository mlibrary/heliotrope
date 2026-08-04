# frozen_string_literal: true

# Restricts a controller's browsing actions (index/facet) to platform admins.
#
# This is included *independently* by CatalogController and AdminCatalogController
# rather than inherited, because the two have different lifetimes for the gate:
#   * AdminCatalogController is admin-only permanently.
#   * CatalogController is admin-only only "for now" - when the public catalog
#     ships, remove the `include PlatformAdminGate` line from CatalogController.
#     Because the gate is included separately, doing so will NOT accidentally
#     expose AdminCatalogController.
module PlatformAdminGate
  extend ActiveSupport::Concern

  included do
    before_action :require_platform_admin, only: %i[index facet]
  end

  private

    # Non-admins who are signed in get an unauthorized page; anonymous visitors
    # are sent to login.
    def require_platform_admin
      return if current_ability&.current_user&.platform_admin?

      if current_user.present?
        render 'hyrax/base/unauthorized', status: :unauthorized
      else
        redirect_to main_app.new_user_session_path
      end
    end
end
