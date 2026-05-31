module Riiif
  class FileSystemFileResolver < AbstractFileSystemResolver
    attr_writer :input_types

    # @return a string suitable for a globbing match
    #   e.g. /base/path/67352ccc-d1b0-11e1-89ae-279075081939.{jp2,tiff,png}
    #   or nil when the id is not valid
    def pattern(id)
      return unless validate_identifier(id: id)
      ::File.join(base_path, "#{id}.{#{input_types.join(',')}}")
    end

    private

      # @return [Boolean] true if the id matches the regex
      def validate_identifier(id:, regex: identifier_regex)
        return true if id.to_s =~ regex
        Rails.logger.warn "Invalid characters in id `#{id}`"
        false
      end

      # Matches on word characters dashes and colons
      def identifier_regex
        /^[\w\-:]+$/
      end

      def input_types
        @input_types ||= %w(png jpg tif tiff jp2)
      end
  end
end
