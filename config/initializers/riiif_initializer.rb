# Tell RIIIF to get files via HTTP (not from the local disk)
Riiif::Image.file_resolver = Riiif::HTTPFileResolver.new

# This tells RIIIF how to resolve the identifier to a URI in Fedora
Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  # This is slow. TODO: find an alternative if possible
  FileSet.find(id).files.first.uri.to_s || ''
end

# In order to return the info.json endpoint, we have to have the full height and width of
# each image. If you are using hydra-file_characterization, you have the height & width
# cached in Solr. The following block directs the info_service to return those values:
Riiif::Image.info_service = lambda do |id, _file|
  doc = ActiveFedora::SolrService.query("{!terms f=id}#{id}").first
  { height: doc["height_is"], width: doc["width_is"] }
end

module Riiif
  def Image.cache_key(id, options)
    # Add a timestamp to "expire" image tiles if a file_set is updated with a new image
    options[:timestamp] = ActiveFedora::SolrService.query("{!terms f=id}#{id}").first["timestamp"]
    str = options.merge(id: id).delete_if { |_, v| v.nil? }.to_s
    # Use a MD5 digest to ensure the keys aren't too long.
    Digest::MD5.hexdigest(str)
  end
end

Riiif::Engine.config.cache_duration_in_days = 7
