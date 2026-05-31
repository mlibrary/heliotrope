module ActionDispatch::Routing
  class Mapper
    # example
    #   iiif_for :image
    def iiif_for(*resources)
      options = resources.extract_options!

      Riiif::Routes.new(self, options.merge(resource: resources.first)).draw
    end
  end
end
