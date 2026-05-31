module SimpleSolrClient::Core::CoreData
  attr_reader :raw_solr_hash


  # Get the core data for this core
  # This is weird in that while the data is about a specific
  # core, we need to call it at the client_url level; hence
  # all the screwing around with force_top_level_url
  #
  # It would make sense to cache this until, say, a commit or a
  # reload, but the added complexity isn't yet worth it.
  def core_data_hash
    cdata = get('admin/cores', {:force_top_level_url => true})
    cdata['status'][core]
  end

  def index
    core_data_hash['index']
  end

  # Time of last modification
  def last_modified
    Time.parse index['lastModified']
  end

  # Total documents
  def number_of_documents
    index['numDocs']
  end

  alias_method :numDocs, :number_of_documents
  alias_method :num_docs, :number_of_documents

  # The (local to the server) data directory
  def data_dir
    core_data_hash['dataDir']
  end


  # Get the index size in megabytes
  def size
    str = index['size']
    num, unit = str.split(/\s+/).compact.map(&:strip)
    num = num.to_f
    case unit
    when "MB"
      num * 1
    when "GB"
      num * 1000
    end
  end

  def instance_dir
    core_data_hash['instanceDir']
  end

  def config_file
    File.join(instance_dir, 'conf', core_data_hash['config'])
  end

  def schema_file
    File.join(instance_dir, 'conf', core_data_hash['schema'])
  end
end


