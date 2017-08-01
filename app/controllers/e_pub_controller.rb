# frozen_string_literal: true

class EPubController < ApplicationController
  def show
    presenter = Hyrax::FileSetPresenter.new(SolrDocument.new(FileSet.find(params[:id]).to_solr), current_ability, request)
    if presenter.epub?
      @title = presenter.title
      @citable_link = presenter.citable_link
      @creator_given_name = presenter.creator_given_name
      @creator_family_name = presenter.creator_family_name
      @back_link = params[:publisher].present? ? URI.join(main_app.root_url, params[:publisher]).to_s : main_app.monograph_catalog_url(presenter.monograph_id)
      @subdomain = presenter.monograph.subdomain
      render layout: false
    else
      Rails.logger.info("### INFO FileSet #{params[:id]} is not an EPub. ###")
      render 'hyrax/base/unauthorized', status: :unauthorized
    end
  rescue Ldp::Gone # tombstone
    raise CanCan::AccessDenied
  end

  def file
    render plain: EPubService.read(params[:id], params[:file] + '.' + params[:format]), layout: false
  rescue
    Rails.logger.info("### INFO Entry #{params[:file]}.#{params[:format]} not found in EPub #{params[:id]}. ###")
    head :not_found
  end
end
