# frozen_string_literal: true

Riiif::ImagesController.class_eval do
  prepend(HeliotropeImagesControllerOverrides = Module.new do
    def image_id
      #
      # HELIO-3308 a.k.a. Cache Busting
      #
      # Cache busting is where we invalidate a cached file
      # and force the browser to retrieve the file from the server.
      #
      # We can instruct the browser to bypass the cache
      # by simply changing the filename. To the browser,
      # this is a completely new resource
      # so it will fetch the resource from the server.
      #
      # The first nine characters of the id is the NOID the rest is the cache buster.
      params[:id][0..8]
    end
  end)
end
