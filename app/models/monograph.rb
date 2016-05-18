# Generated via
#  `rails generate curation_concerns:work Monograph`
class Monograph < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata
  include GlobalID::Identification

  self.indexer = MonographIndexer

  validates :title, presence: { message: 'Your work must have a title.' }

  property :press, predicate: ::RDF::Vocab::MARCRelators.pbl, multiple: false do |index|
    index.as :stored_searchable, :facetable
  end
  validates :press, presence: { message: 'You must select a press.' }

  property :sub_brand, predicate: ::RDF::Vocab::MARCRelators.bsl do |index|
    index.as :symbol
  end

  property :date_published, predicate: ::RDF::Vocab::SCHEMA.datePublished do |index|
    index.as :stored_searchable
  end

  property :isbn, predicate: ::RDF::Vocab::SCHEMA.isbn do |index|
    index.as :stored_searchable
  end

  property :editor, predicate: ::RDF::Vocab::SCHEMA.editor do |index|
    index.as :stored_searchable
  end

  property :copyright_holder, predicate: ::RDF::Vocab::SCHEMA.copyrightHolder do |index|
    index.as :stored_searchable
  end

  property :buy_url, predicate: ::RDF::Vocab::SCHEMA.sameAs do |index|
    index.as :symbol
  end

  property :creator_family_name, predicate: ::RDF::Vocab::FOAF.family_name, multiple: false do |index|
    index.as :stored_searchable
  end

  property :creator_given_name, predicate: ::RDF::Vocab::FOAF.givenname, multiple: false do |index|
    index.as :stored_searchable
  end

  def destroy
    # #76 Deleting a monograph should delete all its sections
    works.each(&:delete)
    super
  end
end
