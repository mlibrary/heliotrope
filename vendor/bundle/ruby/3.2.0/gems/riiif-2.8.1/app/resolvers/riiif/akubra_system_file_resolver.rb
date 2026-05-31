require 'digest'
require 'cgi'
module Riiif
  class AkubraSystemFileResolver < AbstractFileSystemResolver
    attr_accessor :pathroot, :imagetype, :akubraconfig

    def initialize(pr = '/yourfedora/data/datastreamStore/', ir = 'jp2', ac = [[0, 2], [2, 2], [4, 1]])
      super()
      @pathroot = pr
      @imagetype = ir
      @akubraconfig = ac
    end

    def pattern(id)
      fullpid = "info:fedora/#{id}/#{@imagetype}/#{@imagetype}.0"
      md5 = Digest::MD5.new
      md5.update fullpid
      digest = md5.hexdigest
      directorystr = ''
      @akubraconfig.each { |a| directorystr << digest[a[0], a[1]] << '/' }
      filename = CGI.escape(fullpid)
      @pathroot + directorystr + filename
    end
  end
end
