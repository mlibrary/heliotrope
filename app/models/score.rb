# frozen_string_literal: true

class Score < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  include HeliotropeUniversalMetadata

  self.indexer = ::ScoreIndexer
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  property :press, predicate: ::RDF::Vocab::MARCRelators.pbl, multiple: false do |index|
    index.as :stored_searchable, :facetable
  end
  validates :press, presence: { message: 'You must select a press.' }

  # Very specific metadata requirements with so much uncertainty...
  # https://docs.google.com/document/d/1zJlIB7mIV7LIsS2YcsMdGoGq4DkJiH6bc2xI3Yhrwwo/edit
  # https://tools.lib.umich.edu/jira/browse/HELIO-2522
  # I guess this is definitive as of right now
  # https://docs.google.com/spreadsheets/d/1Mcl-Qu0_KdUW2uG4OJ6ta3_vASi2jLcBLnzjVans2tY/edit?ts=5d5ed0ee#gid=0
  # There's also this, which has some data in it:
  # https://docs.google.com/spreadsheets/d/1emqG7q2gZ94mjfzkqzt2fsN1SAHChoO33VXyDsxcvZ0/edit#gid=0

  property :amplified_electronics, predicate: ::RDF::URI.new('http://fulcrum.org/ns#AmplifiedElectronics') do |index|
    index.as :stored_searchable, :facetable
  end

  property :appropriate_occasion, predicate: ::RDF::URI.new('http://fulcrum.org/ns#AppropriateOccasion') do |index|
    index.as :stored_searchable, :facetable
  end

  property :bass_bells_omitted, predicate: ::RDF::URI.new('http://fulcrum.org/ns#BassBellsOmitted') do |index|
    index.as :stored_searchable, :facetable
  end

  property :bass_bells_required, predicate: ::RDF::URI.new('http://fulcrum.org/ns#BassBellsRequired') do |index|
    index.as :stored_searchable, :facetable
  end

  property :composer_contact_information, predicate: ::RDF::URI.new('http://fulcrum.org/ns#ComposerContactInformation') do |index|
    index.as :stored_searchable
  end

  property :composer_diversity, predicate: ::RDF::URI.new('http://fulcrum.org/ns#ComposerDiversity') do |index|
    index.as :stored_searchable, :facetable
  end

  property :duet_or_ensemble, predicate: ::RDF::URI.new('http://fulcrum.org/ns#DuetOrEnsemble'), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :electronics_without_adjustment, predicate: ::RDF::URI.new('http://fulcrum.org/ns#ElectronicWithoutAdjustment'), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :musical_presentation, predicate: ::RDF::URI.new('http://fulcrum.org/ns#MusicalPresentation'), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :music_rights_organization, predicate: ::RDF::URI.new('http://fulcrum.org/ns#MusicRightsOrganization') do |index|
    index.as :stored_searchable
  end

  property :number_of_movements, predicate: ::RDF::URI.new('http://fulcrum.org/ns#NumberOfMovements') do |index|
    index.as :stored_searchable
  end

  property :octave_compass, predicate: ::RDF::URI.new('http://fulcrum.org/ns#OctaveCompass') do |index|
    index.as :stored_searchable, :facetable
  end

  property :premiere_status, predicate: ::RDF::URI.new('http://fulcrum.org/ns#PremiereStatus') do |index|
    index.as :stored_searchable
  end

  property :recommended_carillon_type, predicate: ::RDF::URI.new('http://fulcrum.org/ns#RecommendedCarillonType') do |index|
    index.as :stored_searchable
  end

  property :recommended_for_students, predicate: ::RDF::URI.new('http://fulcrum.org/ns#RecommendedForStudents'), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :rights_granted, predicate: ::RDF::URI.new('http://fulcrum.org/ns#RightsGranted') do |index|
    index.as :stored_searchable
  end

  property :solo, predicate: ::RDF::URI.new('http://fulcrum.org/ns#Solo'), multiple: false do |index|
    index.as :stored_searchable, :facetable
  end

  property :year_of_composition, predicate: ::RDF::URI.new('http://fulcrum.org/ns#YearOfComposition') do |index|
    index.as :stored_searchable
  end

  # This must be included at the end, because it finalizes the metadata
  # schema (by adding accepts_nested_attributes)
  include ::Hyrax::BasicMetadata

  after_create :after_create_jobs
  after_destroy :after_destroy_jobs

  private

    def after_create_jobs
      HandleCreateJob.perform_later(id)
    end

    def after_destroy_jobs
      HandleDeleteJob.perform_later(id)
    end
end
