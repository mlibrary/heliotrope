# frozen_string_literal: true

module SolrDocumentExtensions
  module FileSet
    extend ActiveSupport::Concern

    def allow_display_after_expiration
      Array(self['allow_display_after_expiration_ssim']).first
    end

    def allow_download
      Array(self['allow_download_ssim']).first
    end

    def allow_download_after_expiration
      Array(self['allow_download_after_expiration_ssim']).first
    end

    def allow_hi_res
      Array(self['allow_hi_res_ssim']).first
    end

    def alt_text
      Array(self['alt_text_tesim'])
    end

    def article_creator
      Array(self['article_creator_tesim'])
    end

    def article_display_date
      Array(self['article_display_date_ssim']).first
    end

    def article_issue
      Array(self['article_issue_ssim']).first
    end

    def article_permalink
      Array(self['article_permalink_ssim']).first
    end

    def article_title
      Array(self['article_title_tesim']).first
    end

    def article_volume
      Array(self['article_volume_ssim']).first
    end

    def caption
      Array(self['caption_tesim'])
    end

    def closed_captions
      Array(self['closed_captions_tesim']).first
    end

    def content_type
      Array(self['content_type_tesim'])
    end

    def copyright_status
      Array(self['copyright_status_ssim']).first
    end

    def credit_line
      Array(self['credit_line_ssim']).first
    end

    def display_date
      Array(self['display_date_tesim'])
    end

    def exclusive_to_platform
      Array(self['exclusive_to_platform_ssim']).first
    end

    def external_resource_url
      Array(self['external_resource_url_ssim']).first
    end

    def keywords
      Array(self['keyword_tesim'])
    end

    def permissions_expiration_date
      Array(self['permissions_expiration_date_ssim']).first
    end

    def primary_creator_role
      Array(self['primary_creator_role_tesim'])
    end

    def resource_type
      Array(self['resource_type_tesim']).first
    end

    def rights_granted
      Array(self['rights_granted_ssim']).first
    end

    def section_title
      Array(self['section_title_tesim'])
    end

    def sort_date
      Array(self['sort_date_tesim']).first
    end

    def transcript
      Array(self['transcript_tesim']).first
    end

    def translation
      Array(self['translation_tesim']).first
    end

    def visual_descriptions
      Array(self['visual_descriptions_tesim']).first
    end
  end
end
