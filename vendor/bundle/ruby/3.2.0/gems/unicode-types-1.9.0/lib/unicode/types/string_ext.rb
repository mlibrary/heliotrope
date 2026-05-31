require_relative "../types"

class String
  # Optional string extension for your convenience
  def unicode_types
    Unicode::Types.of(self)
  end
end
