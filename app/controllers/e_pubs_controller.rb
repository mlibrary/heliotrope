# frozen_string_literal: true

class EPubsController < ApplicationController
  before_action :set_presenter, only: %i[show lock shibboleth]
  before_action :set_show, only: %i[show]

  def show
    return render 'hyrax/base/unauthorized', status: :unauthorized unless show?
    @title = @presenter.parent.present? ? @presenter.parent.title : @presenter.title
    @citable_link = @presenter.citable_link
    @back_link = params[:publisher].present? ? URI.join(main_app.root_url, params[:publisher]).to_s : main_app.monograph_catalog_url(@presenter.monograph_id)
    @subdomain = @presenter.monograph.subdomain
    @search_url = main_app.epub_search_url(params[:id], q: "").gsub!(/locale=en&/, '')

    @monograph_presenter = nil
    if @presenter.parent.present?
      @monograph_presenter = Hyrax::PresenterFactory.build_for(ids: [@presenter.parent.id], presenter_class: Hyrax::MonographPresenter, presenter_args: current_ability).first
    end

    @epub_download_presenter = EPubDownloadPresenter.new(@presenter, @monograph_presenter, current_ability)

    CounterService.from(self, @presenter).count(request: 1)

    render layout: false
  end

  def file
    return head :no_content unless show?
    epub = if Dir.exist?(UnpackService.root_path_from_noid(params[:id], 'epub'))
             EPub::Publication.from_directory(UnpackService.root_path_from_noid(params[:id], 'epub'))
           else
             EPub::Publication.null_object
           end
    begin
      render plain: epub.read(params[:file] + '.' + params[:format]), content_type: Mime::Type.lookup_by_extension(params[:format]), layout: false
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
    return render json: { q: params[:q], search_results: [] } if params[:q].length < 3

    results = Rails.cache.fetch(search_cache_key(params[:id], params[:q]), expires_in: 30.days) do
      epub = if Dir.exist?(UnpackService.root_path_from_noid(params[:id], 'epub'))
               EPub::Publication.from_directory(UnpackService.root_path_from_noid(params[:id], 'epub'))
             else
               EPub::Publication.null_object
             end
      epub.search(params[:q])
    end

    render json: results
  end

  def search_cache_key(id, query)
    "epub:" +
      Digest::MD5.hexdigest(query) +
      id +
      ActiveFedora::SolrService.query("{!terms f=id}#{id}", rows: 1).first["timestamp"]
  end

  def lock
    @subscriber = nil
    clear_session_show
    if access?
      set_session_show
      redirect_to epub_path(params[:id])
    else
      @monograph_presenter = nil
      if @presenter.parent.present?
        @monograph_presenter = Hyrax::PresenterFactory.build_for(ids: [@presenter.parent.id], presenter_class: Hyrax::MonographPresenter, presenter_args: current_ability).first
      end
      @institutions = component_institutions
      @products = component_products
      CounterService.from(self, @presenter).count(request: 1, turnaway: "No_License")
      render 'access'
    end
  end

  def shibboleth
    @institution = Institution.find(params[:institution_id])
    entity = @institution&.entity_id
    # encoded_entity = CGI.escape(entity)
    target = epub_url(params[:id])
    # encoded_target = CGI.escape(target)
    login_params = "entityID=#{entity}&target=#{target}"
    # login_params_encoded = CGI.escape(login_params)
    redirect_to "#{Rails.configuration.shibboleth_service_provider_url}/Login?#{login_params}" if @institution&.shibboleth?
  end

  private

    def set_presenter
      @presenter = Hyrax::PresenterFactory.build_for(ids: [params[:id]], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
      unless @presenter.present? && @presenter.epub? # rubocop:disable Style/GuardClause
        Rails.logger.info("EPubsController.set_presenter(#{params[:id]}) is not an EPub.")
        render 'hyrax/base/unauthorized', status: :unauthorized
      end
    end

    def set_show
      return if show?
      redirect_to epub_lock_path(params[:id])
    end

    def show?
      session[:show_set]&.include?(params[:id])
    end

    def set_session_show
      session[:show_set] ||= []
      session[:show_set] << params[:id] unless session[:show_set].include?(params[:id])
      session[:show_set].shift if session[:show_set].length > 10
    end

    def clear_session_show
      session[:show_set] ||= []
      session[:show_set].delete(params[:id]) if session[:show_set].include?(params[:id])
    end

    def access?
      component = Component.find_by(handle: publication.identifier)
      return true if component.blank?
      identifiers = current_institutions.map(&:identifier)
      identifiers << subscriber.identifier
      groupings_lessees = GroupingsLessee.where(lessee: Lessee.where(identifier: identifiers).map(&:id))
      groupings = Grouping.where(id: groupings_lessees.map(&:grouping_id))
      identifiers << groupings.map(&:identifier)
      lessees = Lessee.where(identifier: identifiers.flatten)
      lessees.any? { |lessee| component.lessees.include?(lessee) }
    end

    def component_institutions
      component = Component.find_by(handle: publication.identifier)
      return [] if component.blank?
      lessees = component.lessees(true)
      return [] if lessees.blank?
      Institution.where(identifier: lessees.pluck(:identifier))
    end

    def component_products
      component = Component.find_by(handle: publication.identifier)
      return [] if component.blank?
      products = component.products
      return [] if products.blank?
      products
    end

    def subscribers
      component = Component.find_by(handle: publication.identifier)
      return [] if component.blank?
      component.lessees(true)
    end

    def subscriber
      @subscriber ||= valid_user_signed_in? ? Entity.new(type: :email, identifier: current_user.email) : Entity.null_object
    end

    def publication
      @publication ||= Entity.new(type: :epub, identifier: HandleService.path(@presenter.id))
    end
end
