module SimpleSolrClient::Core::Admin

  # Send a commit command
  # @return self
  def commit
    update({'commit' => {}})
    self
  end

  # Send an optimize command
  # @return self
  def optimize
    update({"optimize" => {}})
    self
  end

  # Reload the core (for when you've changed the schema, solrconfig, synonyms, etc.)
  # Make sure to mark the schema as dirty!
  # @return self
  def reload
    get('admin/cores', {:force_top_level_url => true, :core => core, :action => 'RELOAD'})
    @schema = nil
    self
  end

  # Unload the current core and delete all its files
  # @return The Solr response
  def unload
    get('admin/cores', {:force_top_level_url => true, :core => core, :action => 'UNLOAD', :deleteInstanceDir => true})
  end


end

