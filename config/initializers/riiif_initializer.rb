# Tell RIIIF to get files via HTTP (not from the local disk)
Riiif::Image.file_resolver = Riiif::HTTPFileResolver.new

# This tells RIIIF how to resolve the identifier to a URI in Fedora
Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  FileSet.find(id).files.first.uri.to_s || ''
end

# In order to return the info.json endpoint, we have to have the full height and width of
# each image. If you are using hydra-file_characterization, you have the height & width
# cached in Solr. The following block directs the info_service to return those values:
Riiif::Image.info_service = lambda do |id, _file|
  doc = FileSet.find(id).to_solr
  { height: doc["height_is"], width: doc["width_is"] }
end

Riiif::Engine.config.cache_duration_in_days = 30
