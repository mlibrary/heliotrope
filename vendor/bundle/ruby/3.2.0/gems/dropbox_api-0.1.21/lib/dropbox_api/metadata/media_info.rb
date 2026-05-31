# frozen_string_literal: true
module DropboxApi::Metadata
  # Example of a serialized {MediaInfo} object:
  #
  # ```json
  # {
  #   ".tag": "metadata",
  #   "metadata": {...}
  # }
  # ```
  #
  # or:
  #
  # ```json
  # {
  #   ".tag": "pending"
  # }
  # ```
  class MediaInfo < Base
    class << self
      def new(data)
        klass = class_for(data['.tag'].to_sym)

        if klass == :pending
          :pending
        else
          klass.new(data['metadata'])
        end
      end

      private

      def class_for(tag)
        case tag
        when :pending
          :pending
        when :metadata
          DropboxApi::Metadata::MediaMetadata
        else
          raise ArgumentError, "Unable to build individual result with `#{tag.inspect}`"
        end
      end
    end
  end
end
