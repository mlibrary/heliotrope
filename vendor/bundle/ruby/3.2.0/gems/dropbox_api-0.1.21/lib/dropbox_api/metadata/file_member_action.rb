# frozen_string_literal: true
module DropboxApi::Metadata
  # Example of a serialized FileMemberAction:
  #
  # ```json
  # {
  #   ".tag": "success",
  #   "success": {
  #     ".tag": "viewer"
  #   }
  # }
  # ```
  class FileMemberAction < Base
    class << self
      def new(data)
        tag = data['.tag']
        class_for(tag.to_sym).new(data[tag])
      end

      private

      def class_for(tag)
        case tag
        when :success
          DropboxApi::Metadata::AccessLevel
        when :member_error
          DropboxApi::Errors::FileMemberActionError
        else
          raise ArgumentError, "Unable to build individual result with `#{tag}`"
        end
      end
    end
  end
end
