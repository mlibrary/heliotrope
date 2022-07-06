# frozen_string_literal: true

module CitableLinkPresenter
  extend ActiveSupport::Concern

  delegate :doi, :hdl, :identifier, to: :solr_document

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
    HandleNet::DOI_ORG_PREFIX + doi_path
  end

  def heb?
    heb.present?
  end

  # All HEB Monographs should have their HEB ID set in `identifier`, e.g. `heb_id: heb34567.0001.001`,...
  # which is then used to calculate the HEB-style, title-level handle to display as the "Citable Link",...
  # such as https://hdl.handle.net/2027/heb34567
  # No actual value needs to be stored in `hdl` for HEB Monographs. `doi` still takes precedence if set.
  def heb
    @heb ||= begin
      # HEB ID's do *not* have a '.' after the 'heb'. We won't accept that in the identifier entry.
      heb_id = identifier&.find { |i| i.strip.downcase[/^heb_id:\s*heb[0-9]{5}.[0-9]{4}.[0-9]{3}/] }&.strip&.downcase
      # Always display the title-level handle with no period after 'heb', e.g. 2027/heb34567
      heb_id.present? ? "2027/#{heb_id.gsub(/heb_id:\s*heb/, 'heb')[0, 17]}" : nil
    end
  end

  def heb_path
    heb.presence || ''
  end

  def heb_url
    HandleNet::HANDLE_NET_PREFIX + heb_path
  end

  def handle_path
    hdl.presence || HandleNet.path(id)
  end

  def handle_url
    HandleNet::HANDLE_NET_PREFIX + handle_path
  end
end
