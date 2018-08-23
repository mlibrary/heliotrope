# frozen_string_literal: true

module CitableLinkPresenter
  extend ActiveSupport::Concern

  delegate :doi, :hdl, to: :solr_document

  def citable_link
    if doi.present?
      doi_url
    else
      handle_url
    end
  end

  def doi_path
    doi.presence || ""
  end

  def doi_url
    "https://doi.org/" + doi_path
  end

  def handle_path
    hdl.presence || HandleService.path(id)
  end

  def handle_url
    "http://hdl.handle.net/" + handle_path
  end
end
