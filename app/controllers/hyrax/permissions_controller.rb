# frozen_string_literal: true

# Copied from here (see HELIO-4325):
# https://github.com/samvera/hyrax/blob/4c1a99a6a52c973781dff090c2c98c044ea65e42/app/controllers/hyrax/permissions_controller.rb#L1

module Hyrax
  class PermissionsController < ApplicationController
    load_resource class: ActiveFedora::Base, instance_name: :curation_concern

    attr_reader :curation_concern
    helper_method :curation_concern

    def confirm
      # intentional noop to display default view
    end
    deprecation_deprecate confirm: "Use the #confirm_access action instead."

    def copy
      authorize! :edit, curation_concern
      VisibilityCopyJob.perform_later(curation_concern)
      flash_message = 'Updating file permissions. This may take a few minutes. You may want to refresh your browser or return to this record later to see the updated file permissions.'
      redirect_to [main_app, curation_concern], notice: flash_message
    end

    def confirm_access
      # intentional noop to display default view
    end

    def copy_access
      authorize! :edit, curation_concern

      # HELIOTROPE CHANGE. Gonna wager that kicking off these two jobs asyncronously, each with its own loop over the...
      # Monograph's FileSets is what causes the wrong permission value to be indexed in HELIO-4325
      # InheritPermissionsJob doesn't actually alter the permission value in Fedora, but it does alter loop variable...
      # FileSets that may have the old permission still set. So those get indexed if the timing isn't right.
      # We'll run another job here (SequentialVisibilityCopyAndInheritPermissionsJob) that forces things to run...
      # sequentially.

      ## copy visibility
      # VisibilityCopyJob.perform_later(curation_concern)
      ## copy permissions
      # InheritPermissionsJob.perform_later(curation_concern)
      SequentialVisibilityCopyAndInheritPermissionsJob.perform_later(curation_concern)

      redirect_to [main_app, curation_concern], notice: I18n.t("hyrax.upload.change_access_flash_message")
    end
  end
end
