# frozen_string_literal: true

module Heliotrope
  class FileSetEditForm < Hyrax::Forms::FileSetEditForm
    # In hyrax this seems to be used for FileSetsController.params.require(:file_set).permit
    # If removed you get the "Umpermitted Parameters" error...

    self.terms += %i[creator contributor resource_type caption alt_text copyright_holder
                     description content_type date_created keywords
                     language section_title external_resource
                     copyright_status rights_granted rights_granted_creative_commons
                     exclusive_to_platform permissions_expiration_date
                     allow_display_after_expiration allow_download_after_expiration
                     sort_date allow_download allow_hi_res credit_line
                     holding_contact ext_url_doi_or_handle doi
                     display_date transcript translation redirect_to]

    # the type of metadata customizations used on the Monograph form do not work here (`def self.multiple?` etc). Link:
    # https://samvera.github.io/customize-metadata-other-customizations.html
  end
end
