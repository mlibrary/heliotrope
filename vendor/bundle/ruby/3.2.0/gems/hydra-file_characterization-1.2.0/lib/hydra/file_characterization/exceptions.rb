# frozen_string_literal: true
module Hydra::FileCharacterization
  class FileNotFoundError < RuntimeError
  end

  class ToolNotFoundError < RuntimeError
    def initialize(tool_name)
      super("Unable to find Hydra::FileCharacterization tool with name :#{tool_name}")
    end
  end
end
