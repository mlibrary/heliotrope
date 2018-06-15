# frozen_string_literal: true

module CitableLinkPresenter
  extend ActiveSupport::Concern

  delegate :doi, to: :solr_document

  def citable_link
    if doi.present?
      doi_url
    else
      handle_url
    end
  end

  def doi_url
    doi
  end

  def handle_url
    HandleService.url(id)
  end
end
