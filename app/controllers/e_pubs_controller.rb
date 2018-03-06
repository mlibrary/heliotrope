# frozen_string_literal: true

class EPubsController < ApplicationController
  before_action :set_presenter, only: %i[show lock]
  before_action :set_show, only: %i[show]

  def show
    return render 'hyrax/base/unauthorized', status: :unauthorized unless show?
    @title = @presenter.parent.present? ? @presenter.parent.title : @presenter.title
    @citable_link = @presenter.citable_link
    @creator_given_name = @presenter.creator_given_name
    @creator_family_name = @presenter.creator_family_name
    @back_link = params[:publisher].present? ? URI.join(main_app.root_url, params[:publisher]).to_s : main_app.monograph_catalog_url(@presenter.monograph_id)
    @subdomain = @presenter.monograph.subdomain
    @search_url = main_app.epub_search_url(params[:id], q: "").gsub!(/locale=en&/, '')
    @monograph_presenter = nil
    if @presenter.parent.present?
      @monograph_presenter = Hyrax::PresenterFactory.build_for(ids: [@presenter.parent.id], presenter_class: Hyrax::MonographPresenter, presenter_args: current_ability).first
    end
    render layout: false
  end

  def file
    return head :no_content unless show?
    begin
      render plain: FactoryService.e_pub_publication(params[:id]).read(params[:file] + '.' + params[:format]), content_type: Mime::Type.lookup_by_extension(params[:format]), layout: false
    rescue StandardError => e
      Rails.logger.info("EPubsController.file(#{params[:file] + '.' + params[:format]}) mapping to 'Content-Type': #{Mime::Type.lookup_by_extension(params[:format])} raised #{e}")
      head :no_content
    end
  end

  def search
    return head :not_found unless show?
    if Rails.env == 'development'
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'GET'
      headers['Access-Control-Request-Method'] = '*'
    end

    # due to performance issues, must have 3 or more characters to search
    return head :not_found if params[:q].length < 3

    results = Rails.cache.fetch(search_cache_key(params[:id], params[:q]), expires_in: 30.days) do
      FactoryService.e_pub_publication(params[:id]).search(params[:q])
    end

    if results[:search_results]
      render json: results
    else
      head :not_found
    end
  end

  def search_cache_key(id, query)
    "epub:" +
      Digest::MD5.hexdigest(query) +
      id +
      ActiveFedora::SolrService.query("{!terms f=id}#{id}", rows: 1).first["timestamp"]
  end

  def lock # rubocop:disable Metrics/PerceivedComplexity
    clear_session_show
    if request.request_method_symbol == :get
      if unlocked?
        set_session_show
        redirect_to epub_path(params[:id])
      elsif subscription?
        set_session_show
        redirect_to epub_path(params[:id])
      elsif valid_user_signed_in?
        @subscriptions = Subscription.where(publication: publication.id)
        render
      else
        redirect_to new_user_session_path
      end
    else
      request.request_method_symbol == :delete ? clear_lock : set_lock
      redirect_to monograph_show_path(@presenter.monograph_id)
    end
  end

  def subscription
    clear_session_show
    request.request_method_symbol == :post ? subscribe : unsubscribe
    redirect_to stored_location_for(:user) || root_url
  end

  private

    def set_presenter
      @presenter = Hyrax::FileSetPresenter.new(SolrDocument.new(FileSet.find(params[:id]).to_solr), current_ability, request)
      if @presenter.epub?
        FactoryService.e_pub_publication(params[:id]) # cache epub
      else
        Rails.logger.info("EPubsController.set_presenter(#{params[:id]}) is not an EPub.")
        render 'hyrax/base/unauthorized', status: :unauthorized
      end
    rescue Ldp::Gone # tombstone
      raise CanCan::AccessDenied
    end

    def set_show
      return if show?
      redirect_to lock_epub_path(params[:id])
    end

    def show?
      session[:show_set]&.include?(params[:id])
    end

    def set_session_show
      session[:show_set] ||= []
      session[:show_set] << params[:id] unless session[:show_set].include?(params[:id])
    end

    def clear_session_show
      session[:show_set] ||= []
      session[:show_set].delete(params[:id]) if session[:show_set].include?(params[:id])
    end

    def set_lock
      Subscription.find_or_create_by(subscriber: publication.id, publication: publication.id)
      @locked = true
    end

    def clear_lock
      Subscription.find_by(subscriber: publication.id, publication: publication.id)&.delete
      @locked = false
    end

    def locked?
      @locked ||= Subscription.find_by(subscriber: publication.id, publication: publication.id).present?
    end

    def unlocked?
      !locked?
    end

    def subscription?
      Subscription.find_by(subscriber: subscriber.id, publication: publication.id).present?
    end

    def subscribe
      return unless valid_user_signed_in?
      Subscription.find_or_create_by(subscriber: subscriber.id, publication: publication.id)
    end

    def unsubscribe
      return unless valid_user_signed_in?
      Subscription.find_by(subscriber: subscriber.id, publication: publication.id)&.delete
    end

    def subscriber
      @subscriber ||= valid_user_signed_in? ? Entity.new(type: :email, identifier: current_user.email) : Entity.null_object
    end

    def publication
      @publication ||= Entity.new(type: :epub, identifier: params[:id])
    end
end
