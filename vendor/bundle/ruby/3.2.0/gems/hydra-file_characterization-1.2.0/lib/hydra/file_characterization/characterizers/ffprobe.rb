# frozen_string_literal: true
require 'hydra/file_characterization/exceptions'
require 'hydra/file_characterization/characterizer'

module Hydra::FileCharacterization::Characterizers
  class Ffprobe < Hydra::FileCharacterization::Characterizer
    protected

    def command
      "#{tool_path} -i \"#{filename}\" -print_format xml -show_streams -v quiet"
    end
  end
end
