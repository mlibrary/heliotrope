# frozen_string_literal: true
module DropboxApi
  module OptionsValidator
    # Takes in a list of valid option keys and a hash of options. If one of the
    # keys in the hash is invalid an ArgumentError will be raised.
    #
    # @param valid_option_keys List of valid keys for the options hash.
    # @param options [Hash] Options hash.
    def validate_options(valid_option_keys, options)
      options.keys.each do |key|
        unless valid_option_keys.include? key.to_sym
          raise ArgumentError, "Invalid option `#{key}`"
        end
      end
    end
  end
end
