module Riiif
  class AbstractFileSystemResolver
    extend Deprecation
    attr_accessor :base_path

    def initialize(base_path: nil)
      @base_path = base_path
    end

    def find(id)
      Riiif::File.new(path(id))
    end

    # @param [String] id the id to resolve
    # @return the path of the file
    def path(id)
      search = pattern(id)
      search && Dir.glob(search).first || raise(ImageNotFoundError, search)
    end

    def pattern(_id)
      raise NotImplementedError, "Implement `pattern(id)' in the concrete class"
    end
  end
end
