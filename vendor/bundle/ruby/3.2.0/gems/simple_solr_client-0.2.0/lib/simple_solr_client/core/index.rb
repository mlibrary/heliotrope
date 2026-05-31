module SimpleSolrClient::Core::Index
  # Add the given hash or array of hashes
  # @return self
  def add_docs(*hash_or_hashes)
    update(hash_or_hashes.flatten)
    self
  end

  # A raw delete. Your query needs to be legal (e.g., escaped) already
  # @param [String] q The query to identify items to delete
  # @return self
  def delete(q)
    update({:delete => {:query => q}})
    self
  end

  # Delete all document in the index and immdiately commit
  # @return self
  def clear
    delete('*:*').commit
    self
  end


end
