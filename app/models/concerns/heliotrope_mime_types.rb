# frozen_string_literal: true

# copied from https://github.com/samvera/hydra-works/blob/v1.2.0/lib/hydra/works/models/concerns/file_set/mime_types.rb
# BTW this stuff will eventually be turned into a service in Hyrax, see: https://github.com/samvera/hyrax/issues/4081
# ...which is good because it's pretty much impossible to cleanly override it everywhere it's used right now.

module HeliotropeMimeTypes
  extend ActiveSupport::Concern

  # heliotrope: this method added for https://tools.lib.umich.edu/jira/browse/HELIO-88
  def eps?
    self.class.eps_mime_types.include? mime_type
  end

  def pdf?
    self.class.pdf_mime_types.include? mime_type
  end

  def image?
    self.class.image_mime_types.include? mime_type
  end

  def video?
    self.class.video_mime_types.include? mime_type
  end

  def audio?
    self.class.audio_mime_types.include? mime_type
  end

  def office_document?
    self.class.office_document_mime_types.include? mime_type
  end

  module ClassMethods
    def image_mime_types
      ['image/png', 'image/jpeg', 'image/jpg', 'image/jp2', 'image/bmp', 'image/gif', 'image/tiff']
    end

    def pdf_mime_types
      ['application/pdf']
    end

    # heliotrope: this method added for https://tools.lib.umich.edu/jira/browse/HELIO-88
    def eps_mime_types
      ['application/postscript']
    end

    # heliotrope: 'video/mpg' added for https://tools.lib.umich.edu/jira/browse/HELIO-3438
    def video_mime_types
      ['video/mpg', 'video/mpeg', 'video/mp4', 'video/webm', 'video/x-msvideo', 'video/avi', 'video/quicktime', 'application/mxf']
    end

    def audio_mime_types
      # audio/x-wave is the mime type that fits 0.6.0 returns for a wav file.
      # audio/mpeg is the mime type that fits 0.6.0 returns for an mp3 file.
      ['audio/mp3', 'audio/mpeg', 'audio/wav', 'audio/x-wave', 'audio/x-wav', 'audio/ogg']
    end

    def office_document_mime_types
      ['text/rtf',
       'application/msword',
       'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
       'application/vnd.oasis.opendocument.text',
       'application/vnd.ms-excel',
       'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
       'application/vnd.ms-powerpoint',
       'application/vnd.openxmlformats-officedocument.presentationml.presentation']
    end
  end
end
