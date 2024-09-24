# frozen_string_literal: true

class PreviousNextFileSetPresenter < ApplicationPresenter
  attr_reader :monograph_presenter, :file_set_id, :ordered_member_ids, :num_values, :docs

  def initialize(monograph_presenter, file_set_id)
    @monograph_presenter = monograph_presenter
    @file_set_id = file_set_id
    @ordered_member_ids = @monograph_presenter.solr_document['ordered_member_ids_ssim']
    # This is the number of solr docs to fetch on either side of the file_set_id
    @num_values = 5
    fetch_file_set_docs
  end

  def previous_id?
  end

  def previous_id
    return nil if previous_candidate_ids.empty?

    previous_candidate_ids.reverse_each do |noid|
      @docs[noid]
    end
  end

  def next_id?
  end

  def next_id
  end

  def fetch_file_set_docs
    @docs ||= begin
      noids = previous_candidate_ids.join(",") + "," + next_candidate_ids.join(",")
      @docs = {}
      ActiveFedora::SolrService.query("{!terms f=id}#{noids}", rows: 10).each do |doc|
        @docs[doc['id']] = doc
      end
      @docs
    end
  end

  def previous_candidate_ids
    @previous_candidate_ids ||= begin
      index = @ordered_member_ids.index(file_set_id)
      return [] unless index
      start_index = [0, index - @num_values].max
      @ordered_member_ids[start_index, index - start_index]
    end
  end

  def next_candidate_ids
    @next_candidate_ids ||= begin
      index = @ordered_member_ids.index(file_set_id)
      return nil unless index
      @ordered_member_ids[index + 1, @num_values]
    end
  end

end

