# frozen_string_literal: true

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
  doc = ActiveFedora::SolrService.query("{!terms f=id}#{id}", rows: 1).first
  { height: doc["height_is"], width: doc["width_is"] }
end

module Riiif
  def Image.cache_key(id, options)
    str = options.to_h.merge(id: id).delete_if { |_, v| v.nil? }.to_s
    # Use a MD5 digest to ensure the keys aren't too long.
    # Added "digest_ssim" to "expire" image tiles if a file_set is updated with a new image as...
    # Other fields (like "timestamp") change with any metadata edit, not just a file reversioning.
    # An alternative could be to pull the timestamp from the Hydra Derivatives thumbnail itself
    'riiif:' + Digest::MD5.hexdigest(str) + ActiveFedora::SolrService.query("{!terms f=id}#{id}", rows: 1).first["digest_ssim"]&.first&.split(':')&.last
  end
end

Riiif::Engine.config.cache_duration_in_days = 30
