# frozen_string_literal: true

module API
  module V1
    class NoidsController < API::ApplicationController
      def index
        @noids = if params[:isbn].present?
                   isbn = params[:isbn].gsub!(/\W/, "") || params[:isbn]
                   ActiveFedora::SolrService.query("{!terms f=isbn_numeric}#{isbn}", fl: ['id'], rows: 100_000)
                 elsif params[:doi].present?
                   doi = params[:doi].gsub!(/^https:\/\/doi.org\//, "") || params[:doi]
                   ActiveFedora::SolrService.query("{!terms f=doi_ssim}#{doi}", fl: ['id'], rows: 100_000)
                 elsif params[:identifier].present?
                   ActiveFedora::SolrService.query("{!terms f=identifier_ssim}#{params[:identifier]}", fl: ['id'], rows: 100_000)
                 else
                   ActiveFedora::SolrService.query("+(has_model_ssim:Monograph OR has_model_ssim:FileSet)", fl: ['id'], rows: 100_000)
                 end
      end
    end
  end
end
