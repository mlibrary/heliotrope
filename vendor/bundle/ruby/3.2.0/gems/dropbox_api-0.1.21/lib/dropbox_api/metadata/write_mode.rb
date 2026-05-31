# frozen_string_literal: true
module DropboxApi::Metadata
  # Your intent when writing a file to some path. This is used to determine
  # what constitutes a conflict and what the autorename strategy is.
  #
  # In some situations, the conflict behavior is identical:
  #
  #   - If the target path doesn't contain anything, the file is always
  #     written; no conflict.
  #   - If the target path contains a folder, it's always a conflict.
  #   - If the target path contains a file with identical contents, nothing
  #     gets written; no conflict.
  #
  # The conflict checking differs in the case where there's a file at the
  # target path with contents different from the contents you're trying to
  # write. The value will be one of the following datatypes:
  #
  # - `:add`: Do not overwrite an existing file if there is a conflict. The
  #   autorename strategy is to append a number to the file name. For example,
  #   "document.txt" might become "document (2).txt".
  # - `:overwrite`: Always overwrite the existing file. The autorename strategy
  #   is the same as it is for add.
  # - `:update`: Overwrite if the given "rev" matches the existing file's
  #   "rev". The autorename strategy is to append the string "conflicted copy"
  #   to the file name. For example, "document.txt" might become
  #   "document (conflicted copy).txt" or
  #   "document (Panda's conflicted copy).txt".
  class WriteMode < Base
    VALID_WRITE_MODES = [
      :add,
      :overwrite,
      :update
    ]

    # @example
    #   DropboxApi::Metadata::WriteMode.new :add
    # @example
    #   DropboxApi::Metadata::WriteMode.new :overwrite
    # @example
    #   DropboxApi::Metadata::WriteMode.new :update, "a1c10ce0dd78"
    # @example
    #   DropboxApi::Metadata::WriteMode.new({
    #     ".tag"=>"update",
    #     "update"=>"a1c10ce0dd78"
    #   })
    def initialize(write_mode, options = nil)
      case write_mode
      when Hash
        @write_mode = write_mode
      when String, ::Symbol
        @write_mode = {
          '.tag' => write_mode
        }
        @write_mode[write_mode.to_s] = options unless options.nil?
      end
      @write_mode['.tag'] = @write_mode['.tag'].to_sym

      check_validity
    end

    def check_validity
      unless valid_mode? @write_mode['.tag']
        raise ArgumentError, "Invalid write mode: #{@write_mode[".tag"]}"
      end

      if @write_mode['.tag'] == :update && @write_mode['update'].nil?
        raise ArgumentError, 'Mode `:update` expects a `rev` number'
      end
    end

    def to_hash
      @write_mode
    end

    private

    def valid_mode?(value)
      VALID_WRITE_MODES.include? value
    end
  end
end
