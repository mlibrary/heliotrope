# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work Monograph`
class Monograph < ActiveFedora::Base
  before_validation :clean_identifier

  property :creator_display, predicate: ::RDF::Vocab::FOAF.maker, multiple: false do |index|
    index.as :stored_searchable
  end

  property :buy_url, predicate: ::RDF::Vocab::SCHEMA.sameAs do |index|
    index.as :symbol
  end

  property :isbn, predicate: ::RDF::Vocab::SCHEMA.isbn do |index|
    index.as :stored_searchable
  end

  property :press, predicate: ::RDF::Vocab::MARCRelators.pbl, multiple: false do |index|
    index.as :stored_searchable, :facetable
  end
  validates :press, presence: { message: 'You must select a press.' }

  property :section_titles, predicate: ::RDF::Vocab::DC.tableOfContents, multiple: false do |index|
    index.as :symbol
  end

  property :location, predicate: ::RDF::Vocab::DC.Location, multiple: false do |index|
    index.as :stored_searchable
  end

  property :series, predicate: ::RDF::Vocab::DCMIType.Collection do |index|
    index.as :stored_searchable, :facetable
  end

  property :open_access, predicate: ::RDF::URI.new('http://fulcrum.org/ns#OpenAccess'), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :funder, predicate: ::RDF::Vocab::SCHEMA.funder, multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :funder_display, predicate: ::RDF::URI.new('http://fulcrum.org/ns#FunderDisplay'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :edition_name, predicate: ::RDF::Vocab::BIBO.edition, multiple: false do |index|
    index.as :stored_searchable
  end

  property :previous_edition, predicate: ::RDF::URI.new('http://fulcrum.org/ns#PreviousEdition'), multiple: false do |index|
    index.as :symbol
  end
  validates :previous_edition, format: { allow_blank: true, with: URI.regexp(%w[http https]), message: 'must be a url.' }

  property :next_edition, predicate: ::RDF::URI.new('http://fulcrum.org/ns#NextEdition'), multiple: false do |index|
    index.as :symbol
  end
  validates :next_edition, format: { allow_blank: true, with: URI.regexp(%w[http https]), message: 'must be a url.' }

  property :volume, predicate: ::RDF::URI.new('http://fulcrum.org/ns#Volume'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :oclc_owi, predicate: ::RDF::URI.new('http://fulcrum.org/ns#OclcOwi'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :copyright_year, predicate: ::RDF::URI.new('http://purl.org/dc/terms/dateCopyrighted'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :award, predicate: ::RDF::URI.new('http://fulcrum.org/ns#Award') do |index|
    index.as :stored_searchable
  end

  include HeliotropeUniversalMetadata
  include ::Hyrax::WorkBehavior
  # This must come after the WorkBehavior because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata

  self.indexer = ::MonographIndexer

  after_create :after_create_jobs
  after_destroy :after_destroy_jobs
  after_save :maybe_save_kbart

  validates :title, presence: { message: 'Your work must have a title.' }

  # see https://github.com/samvera/hyrax/issues/5900 and https://mlit.atlassian.net/browse/HELIO-4358
  # I don't think the Hyrax properties should ever have been added. Let the storage layer do its job.
  alias date_uploaded create_date
  alias date_modified modified_date

  private

    def maybe_save_kbart
      component = Greensub::Component.find_by(noid: self.id)
      return if component.nil?
      return unless component&.products.map(&:needs_kbart).any?(true)
      KbartUtils::AddRecord.create_or_update(self)
    end

    def after_create_jobs
      HandleCreateJob.perform_later(HandleNet::FULCRUM_HANDLE_PREFIX + id,
                                    Rails.application.routes.url_helpers.hyrax_monograph_url(id))
    end

    def after_destroy_jobs
      HandleDeleteJob.perform_later(HandleNet::FULCRUM_HANDLE_PREFIX + id)
    end

    def clean_identifier
      self.identifier = self.identifier.map { |id| id.gsub(/[[:space:]]/, '') } if self.identifier.present?
    end
end
