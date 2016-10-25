class ReindexFileSetJob < ActiveJob::Base
  queue_as :reindex_fileset

  def perform(file_set)
    file_set.update_index
  end
end
