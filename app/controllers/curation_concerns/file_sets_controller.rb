module CurationConcerns
  class FileSetsController < ApplicationController
    include CurationConcerns::FileSetsControllerBehavior
    self.form_class = Heliotrope::Forms::FileSetEditForm

    def file_set_params
      params.require(:file_set).permit(
        :visibility_during_embargo, :embargo_release_date,
        :visibility_after_embargo, :visibility_during_lease,
        :lease_expiration_date, :visibility_after_lease, :visibility,
        :creator_family_name, :creator_given_name, :sort_date,
        :book_needs_handles, :allow_download, :allow_hi_res,
        :copyright_status, :rights_granted, :rights_granted_creative_commons,
        :exclusive_to_platform, :permissions_expiration_date,
        :allow_display_after_expiration, :allow_download_after_expiration,
        :credit_line, :holding_contact, :ext_url_doi_or_handle,
        :use_crossref_xml, :display_date, :external_resource,
        :transcript, :copyright_holder,
        description: [], resource_type: [], caption: [], alt_text: [],
        content_type: [], contributor: [], date_created: [], keywords: [],
        language: [], identifier: [], relation: [], title: [],
        primary_creator_role: [], translation: [])
    end

    # def actor
    #  @actor ||= ::CurationConcerns::Actors::AssetActor.new(@file_set, current_user)
    # end
  end
end
