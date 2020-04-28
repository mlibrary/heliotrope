# frozen_string_literal: true

# copied from this commit
# https://github.com/samvera/hyrax/blob/55ce354a372e97b3eb168927d1b84eddcaac3bff/app/services/hyrax/file_set_derivatives_service.rb

Hyrax::FileSetDerivativesService.class_eval do
  prepend(HeliotropeDerivativesServiceOverrides = Module.new do
    # Heliotrope change
    # See #1016
    # When a file_set gets deleted it appears that for
    # some reason this service gets called and it tries to get the mime_type
    # of the file_set AFTER it's been deleted from fedora,
    # so an Ldp::Gone error happens.
    # This is the solution umrdr uses.
    # TODO: Why is this being called generally on deletion, and
    # why after the file_set's been deleted but not before?
    def valid?
      supported_mime_types.include?(mime_type)
    rescue StandardError
      Rails.logger.warn("WARNING: config/initializers/file_set_derivative_monky_patch.rb happened!")
      nil
    end

    def create_derivatives(filename)
      case mime_type
      when *file_set.class.pdf_mime_types             then create_pdf_derivatives(filename)
        # Heliotrope change
        # See https://tools.lib.umich.edu/jira/browse/HELIO-1950
        # when *file_set.class.office_document_mime_types then create_office_document_derivatives(filename)
      when *file_set.class.audio_mime_types           then create_audio_derivatives(filename)
      when *file_set.class.video_mime_types           then create_video_derivatives(filename)
      when *file_set.class.image_mime_types           then create_image_derivatives(filename)
      end
    end

    def create_video_derivatives(filename)
      Hydra::Derivatives::VideoDerivatives.create(filename,
                                                  outputs: [{ label: :thumbnail, format: 'jpg', url: derivative_url('thumbnail') },
                                                            { label: :jpeg, format: 'jpg', url: derivative_url('jpeg') },
                                                            { label: :webm, format: 'webm', url: derivative_url('webm') },
                                                            { label: :mp4, format: 'mp4', url: derivative_url('mp4') }])
    end
  end)
end
