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
    HandleService::DOI_ORG_PREFIX + doi_path
  end

  def handle_path
    hdl.presence || HandleService.path(id)
  end

  def handle_url
    heb_handle || HandleService::HANDLE_NET_PREFIX + handle_path
  end

  def heb_handle
    solr_document.identifier.find { |e| /2027\/heb\./ =~ e }
  end
end
