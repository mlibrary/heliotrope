# Generated via
#  `rails generate curation_concerns:work Monograph`
class Monograph < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata
  validates :title, presence: { message: 'Your work must have a title.' }

  # Move this into its own concern later?
  # RDF predicates are not mapped correctly
  property :date, predicate: ::RDF::URI.new('http://schema.org/datePublished') do |index|
    index.as :stored_searchable
  end
  property :isbn, predicate: ::RDF::URI.new('http://schema.org/isbn') do |index|
    index.as :stored_searchable
  end
  property :editor, predicate: ::RDF::URI.new('http://schema.org/editor') do |index|
    index.as :stored_searchable
  end
  property :copyright_holder, predicate: ::RDF::URI.new('http://schema.org/copyrightHolder') do |index|
    index.as :stored_searchable
  end
  property :buy_URL, predicate: ::RDF::URI.new('http://schema.org/sameAs') do |index|
    index.as :symbol
  end
end
