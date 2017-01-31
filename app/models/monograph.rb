# Generated via
#  `rails generate curation_concerns:work Monograph`
class Monograph < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata
  include GlobalID::Identification
  include StoresCreatorNameSeparately

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

  property :isbn_paper, predicate: ::RDF::URI.new('http://fulcrum.org/ns#isbnSoftcover') do |index|
    index.as :stored_searchable
  end

  property :isbn_ebook, predicate: ::RDF::URI.new('http://fulcrum.org/ns#isbnEbook') do |index|
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
end
