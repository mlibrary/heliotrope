require 'hydra/derivatives'

module Hydra::Works
  class PersistDerivative < Hydra::Derivatives::PersistOutputFileService
    ##
    # Persists a derivative to a FileSet
    # This Service conforms to the signature of `Hydra::Derivatives::PersistOutputFileService`.
    # The purpose of this Service is for use as an alternative to the default Hydra::Derivatives::PersistOutputFileService.
    # It's necessary because the default behavior in Hydra::Derivatives assumes that you're using LDP Basic Containment.
    # Hydra::Works::FileSets use IndirectContainment.  This Service handles that case.
    # This service will always update existing and does not do versioning of persisted files.
    #
    # @param [#read] stream the derivative filestream
    # @param [Hash] directives
    # @option directives [FileSet] :object the FileSet object to attach to
    # @option directives [Symbol] :label the type of derivative
    # extract file type symbol (e.g. :thumbnail) from Hydra::Derivatives created destination_name
    def self.call(stream, directives)
      file = Hydra::Derivatives::IoDecorator.new(stream)
      file.mime_type = new_mime_type(directives.fetch(:format))
      object = directives.fetch(:object)
      type = directives.fetch(:label)
      Hydra::Works::AddFileToFileSet.call(object, file, type, update_existing: true, versioning: false)
    end

    def self.new_mime_type(format)
      case format
      when 'mp4'
        'video/mp4' # default is application/mp4
      when 'webm'
        'video/webm' # default is audio/webm
      else
        MIME::Types.type_for(format).first.to_s
      end
    end
  end
end
