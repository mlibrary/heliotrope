# frozen_string_literal: true
module Hydra::Derivatives
  # This Service is an implementation of the Hydra::Derivatives::PeristOutputFileService
  # It supports basic contained files, which is the behavior associated with Fedora 3 file datastreams that were migrated to Fedora 4
  # and, at the time that this class was authored, corresponds to the behavior of ActiveFedora::Base.attach_file and ActiveFedora::Base.attached_files
  ### Rename this
  class PersistBasicContainedOutputFileService < PersistOutputFileService
    # This method conforms to the signature of the .call method on Hydra::Derivatives::PeristOutputFileService
    # * Persists the file within the object at destination_name
    #
    # NOTE: Uses basic containment. If you want to use direct containment (ie. with PCDM) you must use a different service (ie. Hydra::Works::AddFileToGenericFile Service)
    #
    # @param [IO,String] content the data to be persisted
    # @param [Hash] directives directions which can be used to determine where to persist to.
    # @option directives [String] url This can determine the path of the object.
    # @option directives [String] format The file extension (e.g. 'jpg')
    def self.call(content, directives)
      file = io(content, directives)
      remote_file = retrieve_remote_file(directives)
      remote_file.content = file
      remote_file.mime_type = determine_mime_type(file)
      remote_file.original_name = determine_original_name(file)
      remote_file.save
    end

    # Override this implementation if you need a remote file from a different location
    # @return [ActiveFedora::File]
    def self.retrieve_remote_file(directives)
      uri = URI(directives.fetch(:url))
      raise ArgumentError, "#{uri} is not an http uri" unless uri.scheme == 'http'
      ActiveFedora::File.new(uri.to_s)
    end
    private_class_method :retrieve_remote_file

    # @param [IO,String] content the data to be persisted
    # @param [Hash] directives directions which can be used to determine where to persist to.
    # @return [Hydra::Derivatives::IoDecorator]
    def self.io(content, directives)
      charset = charset(content) if directives[:format] == 'txt' || !directives.fetch(:binary, true)
      Hydra::Derivatives::IoDecorator.new(content, new_mime_type(directives.fetch(:format), charset))
    end
    private_class_method :io

    def self.new_mime_type(extension, charset = nil)
      fmt = mime_format(extension)
      fmt += "; charset=#{charset}" if charset
      fmt
    end

    # Strings (from FullText) have encoding. Retrieve it
    def self.charset(content)
      content.encoding.name if content.respond_to?(:encoding)
    end
    private_class_method :charset

    def self.mime_format(extension)
      case extension
      when 'mp4'
        'video/mp4' # default is application/mp4
      when 'webm'
        'video/webm' # default is audio/webm
      else
        MIME::Types.type_for(extension).first.to_s
      end
    end
    private_class_method :mime_format
  end
end
