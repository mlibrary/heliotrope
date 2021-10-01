# frozen_string_literal: true

module RestfulFedora
  class << self
    def reindex_everything
      Rails.logger.debug "reindex_everything ... "
      restful_fedora = RestfulFedora::Service.new
      Rails.logger.debug "reindex_everything ... restful_fedora"
      contains = restful_fedora.contains
      Rails.logger.debug "reindex_everything ... contains"
      contains.each do |first_level_uri|
        first_level_path = RestfulFedora.uri_to_path(first_level_uri)
        first_level_id = RestfulFedora.path_to_id(first_level_path)
        first_level_object = RestfulFedora.id_to_object(first_level_id)
        Rails.logger.debug { "reindex_everything ... uri: #{first_level_uri} path: #{first_level_path} id: #{first_level_id} object: #{first_level_object}" }
        next if first_level_object.blank?
        first_level_object_and_descendants = ActiveFedora::Indexing::DescendantFetcher.new(first_level_path).descendant_and_self_uris
        batch = []
        first_level_object_and_descendants.each do |uri|
          Rails.logger.debug { "reindex_everything ... to_solr #{ActiveFedora::Base.uri_to_id(uri)}" }
          batch << ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(uri)).to_solr
        end
        Rails.logger.debug "reindex_everything ... batch add"
        ActiveFedora::SolrService.add(batch, softCommit: true)
      end
      Rails.logger.debug "reindex_everything ... commit"
      ActiveFedora::SolrService.commit
    end

    def url
      ActiveFedora.config.credentials[:url]
    end

    def base_path
      ActiveFedora.config.credentials[:base_path].gsub(/^./, '')
    end

    def uri_to_path(uri)
      /(^.*)((#{base_path})(\/..\/..\/..\/..\/)(.*))/.match(uri)[2]
    rescue StandardError => e
      Rails.logger.error("ERROR: RestfulFedora.uri_to_path(#{uri}) #{e.message}")
      uri
    end

    def path_to_id(path)
      ActiveFedora::Base.uri_to_id(path)
    rescue StandardError => e
      Rails.logger.error("ERROR: RestfulFedora.path_to_id(#{path}) #{e.message}")
      path
    end

    def id_to_object(noid)
      ActiveFedora::Base.find(noid)
    rescue StandardError => e
      Rails.logger.error("ERROR: RestfulFedora.path_to_id(#{noid}) #{e.message}")
      nil
    end
  end
end
