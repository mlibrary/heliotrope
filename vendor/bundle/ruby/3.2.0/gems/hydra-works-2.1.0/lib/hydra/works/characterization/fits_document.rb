module Hydra::Works::Characterization
  class FitsDocument
    attr_accessor :ng_xml

    PROXIED_TERMS = %i(
      fits_version format_label file_mime_type exif_tool_version file_size
      date_modified filename original_checksum date_created rights_basis
      copyright_basis copyright_note well_formed valid filestatus_message
      file_title file_author page_count file_language word_count
      character_count paragraph_count line_count table_count graphics_count
      byte_order compression width video_width video_track_width height
      video_height video_track_height color_space profile_name profile_version
      orientation color_map image_producer capture_device scanning_software
      exif_version gps_timestamp latitude longitude character_set markup_basis
      markup_language audio_duration video_duration bit_depth audio_sample_rate
      video_sample_rate video_audio_sample_rate channels data_format offset
      frame_rate audio_bit_rate video_bit_rate track_frame_rate aspect_ratio
    ).freeze

    def proxied_term_hash
      PROXIED_TERMS.map { |t| [t, send(t)] }.to_h
    end

    def self.terminology
      struct = Struct.new(:proxied_term).new
      terminology = Struct.new(:terms)
      terminology.new(PROXIED_TERMS.map { |t| [t, struct] }.to_h)
    end

    #  t.fits_version(proxy: [:fits, :fits_v])
    def fits_version
      ng_xml.css("fits").map { |n| n['version'].text }
    end

    # t.format_label(proxy: [:identification, :identity, :format_label])
    def format_label
      ng_xml.css("fits > identification > identity").map { |n| n['format'] }
    end

    # Can't use .mime_type because it's already defined for this document so method missing won't work.
    # t.file_mime_type(proxy: [:identification, :identity, :mime_type])
    def file_mime_type
      # Sometimes, FITS reports the mimetype attribute as a comma-separated string.
      # All terms are arrays and, in this case, there is only one element, so scan the first.
      ng_xml.css("fits > identification > identity").map { |n| n['mimetype'].split(',').first }
    end

    # t.exif_tool_version(proxy: [:identification, :identity, :tool, :exif_tool_version])
    def exif_tool_version
      ng_xml.css("fits > identification > identity > tool[toolname='Exiftool']").map { |n| n['toolversion'] }
    end

    # t.file_size(proxy: [:fileinfo, :file_size])
    def file_size
      ng_xml.css("fits > fileinfo > size").map(&:text)
    end

    # t.date_modified(proxy: [:fileinfo, :last_modified])
    def date_modified
      ng_xml.css("fits > fileinfo > lastmodified[toolname='Exiftool']").map(&:text)
    end

    #  t.filename(proxy: [:fileinfo, :filename])
    def filename
      ng_xml.css("fits > fileinfo > filename").map(&:text)
    end

    # t.original_checksum(proxy: [:fileinfo, :original_checksum])
    def original_checksum
      ng_xml.css("fits > fileinfo > md5checksum").map(&:text)
    end

    # t.date_created(proxy: [:fileinfo, :date_created])
    def date_created
      ng_xml.css("fits > fileinfo > created[toolname='Exiftool']").map(&:text)
    end

    # t.rights_basis(proxy: [:fileinfo, :rights_basis])
    def rights_basis
      ng_xml.css("fits > fileinfo > rightsBasis").map(&:text)
    end

    # t.copyright_basis(proxy: [:fileinfo, :copyright_basis])
    def copyright_basis
      ng_xml.css("fits > fileinfo > copyrightBasis").map(&:text)
    end

    # t.copyright_basis(proxy: [:fileinfo, :copyright_note])
    def copyright_note
      ng_xml.css("fits > fileinfo > copyrightNote").map(&:text)
    end

    # t.well_formed(proxy: [:filestatus, :well_formed])
    def well_formed
      ng_xml.css("fits > filestatus > well-formed").map(&:text)
    end

    # t.valid(proxy: [:filestatus, :valid])
    def valid
      ng_xml.css("fits > filestatus > valid").map(&:text)
    end

    # t.filestatus_message(proxy: [:filestatus, :status_message])
    def filestatus_message
      ng_xml.css("fits > filestatus > message").map(&:text)
    end

    # t.file_title(proxy: [:metadata, :document, :file_title])
    def file_title
      ng_xml.css("fits > metadata > document > title").map(&:text)
    end

    # t.file_author(proxy: [:metadata, :document, :file_author])
    def file_author
      ng_xml.css("fits > metadata > document > author").map(&:text)
    end

    # t.file_language(proxy: [:metadata, :document, :file_language])
    def file_language
      ng_xml.css("fits > metadata > document > language").map(&:text)
    end

    # t.page_count(proxy: [:metadata, :document, :page_count])
    def page_count
      ng_xml.css("fits > metadata > document > pageCount").map(&:text)
    end

    # t.word_count(proxy: [:metadata, :document, :word_count])
    def word_count
      ng_xml.css("fits > metadata > document > wordCount").map(&:text)
    end

    # t.character_count(proxy: [:metadata, :document, :character_count])
    def character_count
      ng_xml.css("fits > metadata > document > characterCount").map(&:text)
    end

    # t.paragraph_count(proxy: [:metadata, :document, :paragraph_count])
    def paragraph_count
      ng_xml.css("fits > metadata > document > paragraphCount").map(&:text)
    end

    # t.line_count(proxy: [:metadata, :document, :line_count])
    def line_count
      ng_xml.css("fits > metadata > document > lineCount").map(&:text)
    end

    # t.table_count(proxy: [:metadata, :document, :table_count])
    def table_count
      ng_xml.css("fits > metadata > document > tableCount").map(&:text)
    end

    # t.graphics_count(proxy: [:metadata, :document, :graphics_count])
    def graphics_count
      ng_xml.css("fits > metadata > document > graphicsCount").map(&:text)
    end

    # t.byte_order(proxy: [:metadata, :image, :byte_order])
    def byte_order
      ng_xml.css("fits > metadata > image > byteOrder").map(&:text)
    end

    # t.compression(proxy: [:metadata, :image, :compression])
    def compression
      ng_xml.css("fits > metadata > image > compressionScheme").map(&:text)
    end

    # t.width(proxy: [:metadata, :image, :width])
    def width
      ng_xml.css("fits > metadata > image > imageWidth").map(&:text)
    end

    # t.height(proxy: [:metadata, :image, :height])
    def height
      ng_xml.css("fits > metadata > image > imageHeight").map(&:text)
    end

    # t.video_width(proxy: [:metadata, :video, :width])
    def video_width
      ng_xml.css("fits > metadata > video > imageWidth").map(&:text)
    end

    # t.video_height(proxy: [:metadata, :video, :height])
    def video_height
      ng_xml.css("fits > metadata > video > imageHeight").map(&:text)
    end

    # for fits 1
    # t.video_track_width(proxy: [:metadata, :video, :track, :width])
    def video_track_width
      ng_xml.css("fits > metadata > video > track[type='video'] > width").map(&:text)
    end

    # for fits 1
    # t.video_track_height(proxy: [:metadata, :video, :track, :height])
    def video_track_height
      ng_xml.css("fits > metadata > video > track[type='video'] > height").map(&:text)
    end

    #  t.color_space(proxy: [:metadata, :image, :color_space])
    def color_space
      ng_xml.css("fits > metadata > image > colorSpace").map(&:text)
    end

    # t.profile_name(proxy: [:metadata, :image, :profile_name])
    def profile_name
      ng_xml.css("fits > metadata > image > iccProfileName").map(&:text)
    end

    # t.profile_version(proxy: [:metadata, :image, :profile_version])
    def profile_version
      ng_xml.css("fits > metadata > image > iccProfileVersion").map(&:text)
    end

    # t.orientation(proxy: [:metadata, :image, :orientation])
    def orientation
      ng_xml.css("fits > metadata > image > orientation").map(&:text)
    end

    # t.color_map(proxy: [:metadata, :image, :color_map])
    def color_map
      ng_xml.css("fits > metadata > image > colorMap").map(&:text)
    end

    # t.image_producer(proxy: [:metadata, :image, :image_producer])
    def image_producer
      ng_xml.css("fits > metadata > image > imageProducer").map(&:text)
    end

    # t.capture_device(proxy: [:metadata, :image, :capture_device])
    def capture_device
      ng_xml.css("fits > metadata > image > captureDevice").map(&:text)
    end

    # t.scanning_software(proxy: [:metadata, :image, :scanning_software])
    def scanning_software
      ng_xml.css("fits > metadata > image > scanningSoftwareName").map(&:text)
    end

    # t.exif_version(proxy: [:metadata, :image, :exif_version])
    def exif_version
      ng_xml.css("fits > metadata > image > exifVersion[toolname='Exiftool']").map(&:text)
    end

    # t.gps_timestamp(proxy: [:metadata, :image, :gps_timestamp])
    def gps_timestamp
      ng_xml.css("fits > metadata > image > gpsTimeStamp").map(&:text)
    end

    # t.latitude(proxy: [:metadata, :image, :latitude])
    def latitude
      ng_xml.css("fits > metadata > image > gpsDestLatitude").map(&:text)
    end

    # t.longitude(proxy: [:metadata, :image, :longitude])
    def longitude
      ng_xml.css("fits > metadata > image > gpsDestLongitude").map(&:text)
    end

    # t.character_set(proxy: [:metadata, :text, :character_set])
    def character_set
      ng_xml.css("fits > metadata > text > charset").map(&:text)
    end

    # t.markup_basis(proxy: [:metadata, :text, :markup_basis])
    def markup_basis
      ng_xml.css("fits > metadata > text > markupBasis").map(&:text)
    end

    # t.markup_language(proxy: [:metadata, :text, :markup_language])
    def markup_language
      ng_xml.css("fits > metadata > text > markupLanguage").map(&:text)
    end

    # t.audio_duration(proxy: [:metadata, :audio, :duration])
    def audio_duration
      ng_xml.css("fits > metadata > audio > duration").map(&:text)
    end

    # t.bit_depth(proxy: [:metadata, :audio, :bit_depth])
    def bit_depth
      ng_xml.css("fits > metadata > audio > bitDepth").map(&:text)
    end

    # t.audio_sample_rate(proxy: [:metadata, :audio, :sample_rate])
    def audio_sample_rate
      ng_xml.css("fits > metadata > audio > sampleRate").map(&:text)
    end

    # t.channels(proxy: [:metadata, :audio, :channels])
    def channels
      ng_xml.css("fits > metadata > audio > channels").map(&:text)
    end

    # t.data_format(proxy: [:metadata, :audio, :data_format])
    def data_format
      ng_xml.css("fits > metadata > audio > dataFormatType").map(&:text)
    end

    # t.offset(proxy: [:metadata, :audio, :offset])
    def offset
      ng_xml.css("fits > metadata > audio > offset").map(&:text)
    end

    # t.audio_bit_rate(proxy: [:metadata, :audio, :bit_rate])
    def audio_bit_rate
      ng_xml.css("fits > metadata > audio > bitRate").map(&:text)
    end

    # t.video_duration(proxy: [:metadata, :video, :duration])
    def video_duration
      ng_xml.css("fits > metadata > video > duration").map(&:text)
    end

    # t.video_sample_rate(proxy: [:metadata, :video, :sample_rate])
    def video_sample_rate
      ng_xml.css("fits > metadata > video > sampleRate").map(&:text)
    end

    # t.video_audio_sample_rate(proxy: [:metadata, :video, :audio_sample_rate])
    def video_audio_sample_rate
      ng_xml.css("fits > metadata > video > audioSampleRate").map(&:text)
    end

    # t.frame_rate(proxy: [:metadata, :video, :frame_rate])
    def frame_rate
      ng_xml.css("fits > metadata > video > frameRate").map(&:text)
    end

    # t.video_bit_rate(proxy: [:metadata, :video, :bit_rate])
    def video_bit_rate
      ng_xml.css("fits > metadata > video > bitRate").map(&:text)
    end

    # t.track_frame_rate(proxy: [:metadata, :video, :track, :frame_rate])
    def track_frame_rate
      ng_xml.css("fits > metadata > video > track[type='video'] > frameRate").map(&:text)
    end

    # t.aspect_ratio(proxy: [:metadata, :video, :track, :aspect_ratio])
    def aspect_ratio
      ng_xml.css("fits > metadata > video > track[type='video'] > aspectRatio").map(&:text)
    end

    # Cleanup phase; ugly name to avoid collisions.
    # The send construct here is required to fix up values because the setters
    # are not defined, but rather applied with method_missing.
    def __cleanup__
      # Add any other scrubbers here; don't return any particular value
      nil
    end

    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.fits(xmlns: 'http://hul.harvard.edu/ois/xml/ns/fits/fits_output',
                 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                 'xsi:schemaLocation' => "http://hul.harvard.edu/ois/xml/ns/fits/fits_output
                 http://hul.harvard.edu/ois/xml/xsd/fits/fits_output.xsd",
                 version: '0.6.0', timestamp: '1/25/12 11:04 AM') do
          xml.identification { xml.identity(toolname: 'FITS') }
        end
      end
      builder.doc
    end
  end
end
