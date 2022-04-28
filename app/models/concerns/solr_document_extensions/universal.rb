# frozen_string_literal: true

module SolrDocumentExtensions
  module Universal
    extend ActiveSupport::Concern

    def copyright_holder
      Array(self['copyright_holder_tesim']).first
    end

    def date_published
      # note `type: :date` as this is set to a DateTime in PublishJob and, as the property is declared `stored_searchable`, it will hit this line:
      # https://github.com/samvera/active_fedora/blob/511ee837cd9a461021e53d5e20f362b634de39a8/lib/active_fedora/indexing/default_descriptors.rb#L99
      Array(self['date_published_dtsim']).first&.to_date.to_s.presence ||
          '<PublishJob never run>'
    end

    def doi
      Array(self['doi_ssim']).first
    end

    def has_model # rubocop:disable Naming/PredicateName
      Array(self['has_model_ssim']).first
    end

    def hdl
      Array(self['hdl_ssim']).first
    end

    def holding_contact
      Array(self['holding_contact_ssim']).first
    end

    def tombstone
      Array(self['tombstone_ssim']).first
    end

    def tombstone_message
      Array(self['tombstone_message_tesim']).first
    end
  end
end
