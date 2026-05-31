# frozen_string_literal: true
require 'hydra/file_characterization/exceptions'
require 'hydra/file_characterization/characterizer'
require 'logger'
module Hydra::FileCharacterization::Characterizers
  class Fits < Hydra::FileCharacterization::Characterizer
    protected

    def command
      "#{tool_path} -i \"#{filename}\""
    end

    # Remove any non-XML output that precedes the <?xml> tag
    # See: https://github.com/harvard-lts/fits/issues/20
    #      https://github.com/harvard-lts/fits/issues/40
    #      https://github.com/harvard-lts/fits/issues/46
    def post_process(raw_output)
      md = /\A(.*)(<\?xml.*)\Z/m.match(raw_output)
      logger.warn "FITS produced non-xml output: \"#{md[1].chomp}\"" unless md[1].empty?
      md[2]
    end
  end
end
