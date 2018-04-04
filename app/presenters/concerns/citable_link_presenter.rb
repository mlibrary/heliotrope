# frozen_string_literal: true

module CitableLinkPresenter
  extend ActiveSupport::Concern

  delegate :hdl, :doi, to: :solr_document

  def citable_link
    if doi.present?
      doi_url
    else
      handle_url
    end
  end

  def handle_url
    HandleService.url(self)
  end

  def doi_url
    doi
  end
end
