# frozen_string_literal: true

class Collection < ActiveFedora::Base
  include ::CurationConcerns::CollectionBehavior
  # You can replace these metadata if they're not suitable
  include CurationConcerns::BasicMetadata
end
