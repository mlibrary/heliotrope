# frozen_string_literal: true

class TombstonesController < ApplicationController
  def index
    @tombstones = file_set_docs.sort { |a, b| a['permissions_expiration_date_ssim'].first <=> b['permissions_expiration_date_ssim'].first }.reverse
  end

  private

    def file_set_docs
      ActiveFedora::SolrService.query('+has_model_ssim:FileSet AND (+permissions_expiration_date_ssim:["" TO *] OR +allow_display_after_expiration_ssim:["" TO *] OR +allow_download_after_expiration_ssim:["" TO *])',
                                      fl: %w[id monograph_id_ssim permissions_expiration_date_ssim allow_display_after_expiration_ssim allow_download_after_expiration_ssim],
                                      rows: 100_000) || []
    end
end
