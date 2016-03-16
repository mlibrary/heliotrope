class Section < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata
  include GlobalID::Identification
  validates :title, presence: { message: 'Your work must have a title.' }

  property :date_published, predicate: ::RDF::Vocab::SCHEMA.datePublished do |index|
    index.as :stored_searchable
  end
end
