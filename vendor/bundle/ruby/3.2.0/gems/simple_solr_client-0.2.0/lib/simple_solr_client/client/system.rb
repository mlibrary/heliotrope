module SimpleSolrClient
  # Attributes of the solr process itself
  class System

    def initialize(sysresp)
      @resp = sysresp
    end

    # @return [String] Full lucene version, with release data and everything
    def lucene_full_version
      @resp['lucene']['lucene-impl-version']
    end

    # @return [String] Lucene version as M.m.p
    def lucene_semver_version
      @resp['lucene']['lucene-spec-version']
    end

    # @return [Integer] The major lucene version (e.g., 7)
    def lucene_major_version
      lucene_full_version.split('.').first.to_i
    end

    # @return [String] Full lucene version, with release data and everything
    def solr_full_version
      @resp['lucene']['solr-impl-version']
    end

    # @return [String] Lucene version as M.m.p
    def solr_semver_version
      @resp['lucene']['solr-spec-version']
    end

    # @return [Integer] The major lucene version (e.g., 7)
    def solr_major_version
      solr_semver_version.split('.').first.to_i
    end
  end
end