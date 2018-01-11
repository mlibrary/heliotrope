# frozen_string_literal: true

# See #1016
# When a file_set gets deleted it appears that for
# some reason this service gets called and it tries to get the mime_type
# of the file_set AFTER it's been deleted from fedora,
# so an Ldp::Gone error happens.
# This is the solution umrdr uses.
# TODO: Why is this being called generally on deletion, and
# why after the file_set's been deleted but not before?
Hyrax::FileSetDerivativesService.class_eval do
  def valid?
    supported_mime_types.include?(mime_type)
  rescue
    Rails.logger.warn("WARNING: config/initializers/file_set_derivative_monky_patch.rb happened!")
    nil
  end

  # seeing as this monkey patch already exists I'm going to customize our derivative creation here:
  # 1) FYI, we're allowing full text extraction on PDFs (default Hyrax behavior)
  # 2) we don't want derivatives created for office documents (just using our glyphicon override), commenting that out
  def create_derivatives(filename)
    case mime_type
    when *file_set.class.pdf_mime_types             then create_pdf_derivatives(filename)
    # when *file_set.class.office_document_mime_types then create_office_document_derivatives(filename)
    when *file_set.class.audio_mime_types           then create_audio_derivatives(filename)
    when *file_set.class.video_mime_types           then create_video_derivatives(filename)
    when *file_set.class.image_mime_types           then create_image_derivatives(filename)
    end
  end
end
