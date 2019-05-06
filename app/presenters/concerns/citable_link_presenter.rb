# frozen_string_literal: true

module CitableLinkPresenter
  extend ActiveSupport::Concern

  delegate :doi, :hdl, to: :solr_document

  def citable_link
    if doi.present?
      doi_url
    elsif heb.present?
      heb_url
    else
      handle_url
    end
  end

  def doi?
    doi.present?
  end

  def doi_path
    doi.presence || ''
  end

  def doi_url
    HandleService::DOI_ORG_PREFIX + doi_path
  end

  def heb?
    heb.present?
  end

  def heb
    @heb ||= begin
      match = /^(.*)(2027\/heb\.)(.*)$/i.match(solr_document.identifier.find { |e| /2027\/heb\./i =~ e } || '')
      (match[2] + match[3]).downcase if match
    end
  end

  def heb_path
    heb.presence || ''
  end

  def heb_url
    HandleService::HANDLE_NET_PREFIX + heb_path
  end

  def handle_path
    hdl.presence || HandleService.path(id)
  end

  def handle_url
    HandleService::HANDLE_NET_PREFIX + handle_path
  end
end
