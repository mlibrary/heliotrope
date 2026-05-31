# frozen_string_literal: true
module Hydra::FileCharacterization
  module Characterizers
  end

  module_function

  def characterizer(tool_name)
    characterizer_name = characterizer_name_from(tool_name)
    if Characterizers.const_defined?(characterizer_name)
      Characterizers.const_get(characterizer_name)
    else
      raise ToolNotFoundError, tool_name
    end
  end

  def characterizer_name_from(tool_name)
    tool_name.to_s.gsub(/(?:^|_)([a-z])/) { Regexp.last_match(1).upcase }
  end

  def characterize_with(tool_name, path_to_file, path_to_tool)
    if path_to_tool.respond_to?(:call)
      path_to_tool.call(path_to_file)
    else
      tool_obj = characterizer(tool_name).new(path_to_file, path_to_tool)
      tool_obj.call
    end
  end
end

require 'hydra/file_characterization/characterizers/fits'
require 'hydra/file_characterization/characterizers/ffprobe'
require 'hydra/file_characterization/characterizers/fits_servlet'
