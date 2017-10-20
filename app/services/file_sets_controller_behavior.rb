# frozen_string_literal: true

module FileSetsControllerBehavior
  # This gets prepended to Hyrax::FileSetsController
  # Is services/ really the best place for this?
  Hyrax::FileSetsController.form_class = ::Heliotrope::FileSetEditForm

  def show
    # local heliotrope change
    redirect_to redirect_link, status: :moved_permanently if redirect_link.present?
    respond_to do |wants|
      wants.html { presenter }
      wants.json { presenter }
      additional_response_formats(wants)
    end
  end

  def redirect_link
    # there may be a use case in future for external redirection, but for right now it's just FileSet to FileSet
    link = file_set_doc['redirect_to_ssim']&.first
    return nil if link.blank?
    if link&.length == 9 && ::FileSet.where(id: link).present?
      Rails.application.routes.url_helpers.hyrax_file_set_path(link)
    else
      '/'
    end
  end

  def file_set_doc
    ActiveFedora::SolrService.query("{!terms f=id}#{params[:id]}", rows: 1)&.first || {}
  end
end
