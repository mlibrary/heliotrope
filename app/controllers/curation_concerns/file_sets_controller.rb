module CurationConcerns
  class FileSetsController < ApplicationController
    include CurationConcerns::FileSetsControllerBehavior

    self.form_class = Heliotrope::Forms::FileSetEditForm

    def file_set_params
      fix_visibility

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
        :use_crossref_xml, :external_resource,
        :transcript, :copyright_holder, :doi, :hdl,
        description: [], resource_type: [], caption: [], alt_text: [],
        content_type: [], contributor: [], date_created: [], keywords: [],
        language: [], identifier: [], section_title: [], title: [],
        primary_creator_role: [], translation: [], display_date: [])
    end

    # We kept getting errors with visibility settings, see #272 and #280
    # This fails far up the stack in hydra-access-controls with errors similar to
    # https://groups.google.com/forum/#!searchin/hydra-tech/visibility/hydra-tech/bEjUiLS6HiU/uWvi9ssVAQAJ
    # either saying embargo/lease is not a valid visibility, or setting OA files as lease and privates as
    # embargos. Since we're allowing users to choose visibility for FileSets (not just inherit from Monograph),
    # it appears we need to tweak this to get it working? This ugly hack solves an immediate problem, but
    # TODO: decide if overriding Hydra::AccessControls::Embargoable somehow is a better path forward,
    # see: https://github.com/ualbertalib/sufia/commit/4edf55214f7064e8a4aec7290f4f1b30a60571d8
    def fix_visibility
      case params[:file_set][:visibility]
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        params[:file_set].delete :visibility_during_embargo
        params[:file_set].delete :embargo_release_date
        params[:file_set].delete :visibility_after_embargo
        params[:file_set].delete :visibility_during_lease
        params[:file_set].delete :lease_expiration_date
        params[:file_set].delete :visibility_after_lease
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
        params[:file_set][:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        params[:file_set].delete :visibility_during_embargo
        params[:file_set].delete :embargo_release_date
        params[:file_set].delete :visibility_after_embargo
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
        params[:file_set][:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        params[:file_set].delete :visibility_during_lease
        params[:file_set].delete :lease_expiration_date
        params[:file_set].delete :visibility_after_lease
      end
    end

    # Override CurationConcerns::FileSetControllerBehavior create method
    # routed to /files (POST)
    # TODO: Fix "code smell" in CurationConcerns.
    def create
      if !(params.key?(:file_set) && params.fetch(:file_set).key?(:files))
        respond_to do |wants|
          wants.html do
            flash[:error] = 'You must attach a file!'
            render action: 'new'
          end
          wants.all do
            create_from_upload(params)
          end
        end
      else
        create_from_upload(params)
      end
    end

    def create_from_upload(params)
      # check error condition No files
      return render_json_response(response_type: :bad_request, options: { message: 'Error! No file to save' }) unless params.key?(:file_set) && params.fetch(:file_set).key?(:files)

      file = params[:file_set][:files].detect { |f| f.respond_to?(:original_filename) }
      if !file
        render_json_response(response_type: :bad_request, options: { message: 'Error! No file for upload', description: 'unknown file' })
      elsif empty_file?(file)
        render_json_response(response_type: :unprocessable_entity, options: { errors: { files: "#{file.original_filename} has no content! (Zero length file)" }, description: t('curation_concerns.api.unprocessable_entity.empty_file') })
      else
        process_file(file)
      end
    rescue RSolr::Error::Http => error
      logger.error "FileSetController::create rescued #{error.class}\n\t#{error}\n #{error.backtrace.join("\n")}\n\n"
      render_json_response(response_type: :internal_error, options: { message: 'Error occurred while creating a FileSet.' })
    ensure
      # remove the tempfile (only if it is a temp file)

      # I know this is terrible, but without it the file is deleted before IngestFileJob can run!!!
      # Sufia (and presumably Hyrax) uses CarrierWave for file uploads, but CC does not.
      # It sort of does it's own thing which seems to cause a condition where the uploaded
      # temp "RackMultipart" file gets deleted before ingest can run, meaning we get a file_set without
      # a file. And if ingest doesn't run, neither does characterization or derivatives which
      # is of course bad.
      # So this awful "sleep" is completly temporary:
      # 1. This will all be gone when we upgrade to Hyrax
      # 2. The importer never gets here, this is only for "manual" file_set creation by users via the UI
      #    and we don't even have a use case for that right now.
      # 3. So this only happens for developers trying things out in the UI.
      # 4. This is only for "create". Even "update" never gets here, that's completly different
      # Obviously this can't be permanent.
      # TODO: fix this.
      Rails.logger.debug("Waiting in #{__FILE__}:#{__LINE__}, see #627")
      sleep 10

      file.tempfile.delete if file.respond_to?(:tempfile)
    end
  end
end
