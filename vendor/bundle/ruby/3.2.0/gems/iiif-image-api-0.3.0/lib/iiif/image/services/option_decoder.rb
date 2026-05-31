# frozen_string_literal: true

module IIIF::Image
  # Decodes the URL parameters into a Transformation object
  class OptionDecoder
    OUTPUT_FORMATS = %w(webp jpg png).freeze
    QUALITY_OPTIONS = %w(bitonal gray grey default color)

    # a helper method for instantiating the OptionDecoder
    # @param [ActiveSupport::HashWithIndifferentAccess] options
    def self.decode(options)
      new(options).decode
    end

    # @param [ActiveSupport::HashWithIndifferentAccess] options
    def initialize(options)
      @options = options
    end

    ##
    # @return [Transformation]
    def decode
      IIIF::Image::Transformation.new(region: decode_region(@options.delete(:region)),
                               size: decode_size(@options.delete(:size)),
                               quality: decode_quality(@options[:quality]),
                               rotation: decode_rotation(@options[:rotation]),
                               format: decode_format(@options[:format]))
    end

    def decode_quality(quality)
      return quality if QUALITY_OPTIONS.include?(quality)
      return 'default' if quality.nil?
      raise InvalidAttributeError, "Unsupported quality: #{quality}"
    end

    def decode_rotation(rotation)
      return 0 if rotation.nil? || rotation == '0'
      begin
        Float(rotation)
      rescue ArgumentError
        raise InvalidAttributeError, "Unsupported rotation: #{rotation}"
      end
    end

    def decode_format(format)
      format ||= 'jpg'
      return format if OUTPUT_FORMATS.include?(format)
      raise InvalidAttributeError, "Unsupported format: #{format}"
    end

    # rubocop:disable Metrics/AbcSize
    def decode_region(region)
      if region.nil? || region == 'full'
        Region::Full.new
      elsif md = /^pct:(\d+(?:.\d+)?),(\d+(?:.\d+)?),(\d+(?:.\d+)?),(\d+(?:.\d+)?)$/.match(region)
        Region::Percent
          .new(md[1].to_f, md[2].to_f, md[3].to_f, md[4].to_f)
      elsif md = /^(\d+),(\d+),(\d+),(\d+)$/.match(region)
        Region::Absolute.new(md[1].to_i, md[2].to_i, md[3].to_i, md[4].to_i)
      elsif region == 'square'
        Region::Square.new
      else
        raise InvalidAttributeError, "Invalid region: #{region}"
      end
    end

    def decode_size(size)
      if size.nil? || size == 'max'
        Size::Max.new
      elsif size == 'full'
        Size::Full.new # Deprecated
      elsif md = /^,(\d+)$/.match(size)
        Size::Height.new(md[1].to_i)
      elsif md = /^(\d+),$/.match(size)
        Size::Width.new(md[1].to_i)
      elsif md = /^pct:(\d+(?:.\d+)?)$/.match(size)
        Size::Percent.new(md[1].to_f)
      elsif md = /^(\d+),(\d+)$/.match(size)
        Size::Absolute.new(md[1].to_i, md[2].to_i)
      elsif md = /^!(\d+),(\d+)$/.match(size)
        Size::BestFit.new(md[1].to_i, md[2].to_i)
      else
        raise InvalidAttributeError, "Invalid size: #{size}"
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
