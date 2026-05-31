module Riiif
  # Creates names for a temporary file
  class LinkNameService
    def self.create
      ::File.join(Dir.tmpdir, SecureRandom.uuid) + '.bmp'
    end
  end
end
