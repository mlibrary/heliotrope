module CurationConcerns
  class FileSetsController < ApplicationController
    include CurationConcerns::FileSetsControllerBehavior
    self.form_class = Heliotrope::Forms::FileSetEditForm

    def file_set_params
      params.require(:file_set).permit(
        :visibility_during_embargo, :embargo_release_date,
        :visibility_after_embargo, :visibility_during_lease,
        :lease_expiration_date, :visibility_after_lease, :visibility,
        resource_type: [], caption: [], alt_text: [], copyright_holder: [],
        description: [], content_type: [], creator: [], contributor: [],
        date_created: [], keywords: [], language: [], identifier: [],
        relation: [], title: [])
    end

    def actor
      @actor ||= ::CurationConcerns::AssetActor.new(@file_set, current_user)
    end
  end
end
