module Hydra::Works
  # Holds an original file and potentially some derivatives as well as some
  # descriptive metadata
  class FileSet < ActiveFedora::Base
    include Hydra::Works::FileSetBehavior
  end
end
