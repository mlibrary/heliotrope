module Heliotrope::Forms
  class FileSetEditForm < CurationConcerns::Forms::FileSetEditForm
    self.terms += [:resource_type, :caption, :alt_text, :copyright_holder,
                   :description, :content_type, :date_created, :keywords,
                   :language, :identifier, :relation, :external_resource,
                   :book_needs_handles, :creator_family_name, :creator_given_name,
                   :copyright_status, :rights_granted, :rights_granted_creative_commons,
                   :exclusive_to_platform, :permissions_expiration_date,
                   :allow_display_after_expiration, :allow_download_after_expiration,
                   :sort_date, :search_year, :allow_download, :allow_hi_res, :credit_line,
                   :holding_contact, :ext_url_doi_or_handle, :use_crossref_xml,
                   :primary_creator_role, :display_date, :transcript, :translation]
  end
end
