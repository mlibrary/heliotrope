# frozen_string_literal: true
module Hydra::Derivatives
  class PersistOutputFileService
    # Persists the file within the object at destination_name.  Uses basic containment.
    # If you want to use direct containment (ie. with PCDM) you must use a different service (ie. Hydra::Works::AddFileToGenericFile Service)
    # @param [String] file_path the path to the file to be added
    # @param [Hash] directives directions which can be used to determine where to persist to.
    # @option directives [String] url This can determine the path of the object.
    def self.call(_file_path, _directives)
      raise NotImplementedError, "PersistOutputFileService is an abstract class. Implement `call' on #{self.class.name}"
    end

    # @param file [Hydra::Derivatives::IoDecorator]
    def self.determine_original_name(file)
      if file.respond_to? :original_filename
        file.original_filename
      else
        "derivative"
      end
    end

    # @param file [Hydra::Derivatives::IoDecorator]
    def self.determine_mime_type(file)
      if file.respond_to? :mime_type
        file.mime_type
      else
        "application/octet-stream"
      end
    end
  end
end
