module Hydra::Works
  module Derivatives
    extend ActiveSupport::Concern
    include Hydra::Derivatives

    included do
      # Sets output_file_service to PersistDerivative instead of default Hydra::Derivatives::PersistBasicContainedOutputFileService
      Hydra::Derivatives.output_file_service = Hydra::Works::PersistDerivative
    end

    # Note, these derivatives are being fetched from Fedora, so there may be more
    # network traffic than necessary.  If you want to avoid this, set up a
    # source_file_service that fetches the files locally, as is done in CurationConcerns.
    def create_derivatives
      case original_file.mime_type
      when *self.class.pdf_mime_types
        Hydra::Derivatives::PdfDerivatives.create(self, source: :original_file, outputs: [{ label: :thumbnail, format: 'jpg', size: '338x493', object: self }])
      when *self.class.office_document_mime_types
        Hydra::Derivatives::DocumentDerivatives.create(self, source: :original_file, outputs: [{ label: :thumbnail, format: 'jpg', size: '200x150>', object: self }])
      when *self.class.video_mime_types
        Hydra::Derivatives::VideoDerivatives.create(self, source: :original_file, outputs: [{ label: :thumbnail, format: 'jpg', object: self }])
      when *self.class.image_mime_types
        Hydra::Derivatives::ImageDerivatives.create(self, source: :original_file, outputs: [{ label: :thumbnail, format: 'jpg', size: '200x150>', object: self }])
      end
    end
  end
end
