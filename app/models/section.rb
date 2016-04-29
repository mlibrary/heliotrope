class Section < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata
  include GlobalID::Identification

  validates :title, presence: { message: 'Your work must have a title.' }

  property :date_published, predicate: ::RDF::Vocab::SCHEMA.datePublished do |index|
    index.as :stored_searchable
  end

  # TODO: is SCHEMA.isPartOf ok for the Section's monograph_id?
  property :monograph_id, predicate: ::RDF::Vocab::SCHEMA.isPartOf, multiple: false do |index|
    index.as :symbol
  end
end
