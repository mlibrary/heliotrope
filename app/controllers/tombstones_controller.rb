# frozen_string_literal: true

class TombstonesController < ApplicationController
  def index
    model_docs = has_model_docs.sort do |a, b|
      if a['has_model_ssim'].first == 'Monograph' && b['has_model_ssim'].first == 'Monograph'
        a['id'] <=> b['id']
      elsif a['has_model_ssim'].first == 'Monograph'
        rv = a['id'] <=> (b['monograph_id_ssim'].first || '')
        rv == 0 ? -1 : rv
      elsif b['has_model_ssim'].first == 'Monograph'
        rv = (a['monograph_id_ssim'].first || '') <=> b['id']
        rv == 0 ? 1 : rv
      else
        a['monograph_id_ssim'].first <=> b['monograph_id_ssim'].first
      end
    end
    tombstone_docs = model_docs.sort do |a, b|
      if a['tombstone_ssim'].present? && b['tombstone_ssim'].present?
        0
      elsif a['tombstone_ssim'].present?
        -1
      elsif b['tombstone_ssim'].present?
        1
      else
        0
      end
    end
    @tombstones = tombstone_docs.sort do |a, b|
      if a['permissions_expiration_date_ssim'].present? && b['permissions_expiration_date_ssim'].present?
        b['permissions_expiration_date_ssim'].first <=> a['permissions_expiration_date_ssim'].first
      elsif a['permissions_expiration_date_ssim'].present?
        -1
      elsif b['permissions_expiration_date_ssim'].present?
        1
      else
        0
      end
    end
  end

  private

    def has_model_docs
      ActiveFedora::SolrService.query('(tombstone_ssim:["" TO *]) OR (+has_model_ssim:FileSet AND (permissions_expiration_date_ssim:["" TO *] OR allow_display_after_expiration_ssim:["" TO *] OR allow_download_after_expiration_ssim:["" TO *]))',
                                      fl: %w[id has_model_ssim tombstone_ssim monograph_id_ssim permissions_expiration_date_ssim allow_display_after_expiration_ssim allow_download_after_expiration_ssim],
                                      rows: 100_000) || []
    end
end
