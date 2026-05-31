# Have to explicitly require this file to get the monkey
# patching of String#scrub in there, this file won't and shouldn't
# be 'require'd in automatically.
#
# However if there's already a String#scrub defiend, requiring
# this file will do nothing.

class String
  # Only monkey patch if not already defined....
  unless instance_methods.include? :scrub
    def scrub(replacement=nil, &block)
      ScrubRb.scrub(self, replacement, &block)
    end

    def scrub!(*args)
      self.replace( self.scrub(*args) )
    end
  end

end