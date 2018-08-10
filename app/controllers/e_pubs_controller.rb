# frozen_string_literal: true

class EPubsController < ApplicationController
  before_action :set_presenter, only: %i[show download_chapter download_section search]
  before_action :set_show, only: %i[show download_chapter download_section]

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
    epub = EPub::Publication.from_directory(UnpackService.root_path_from_noid(params[:id], 'epub'))

    file = epub.file(params[:file] + '.' + params[:format])
    file = file.to_s.sub(/releases\/\d+/, "current")
    response.headers['X-Sendfile'] = file

    begin
      send_file file
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
      epub = EPub::Publication.from_directory(UnpackService.root_path_from_noid(params[:id], 'epub'))
      epub.search(params[:q])
    end

    render json: results
  end

  def search_cache_key(id, query)
    "epub:" +
      Digest::MD5.hexdigest(query) +
      id +
      @presenter.date_modified.to_s
  end

  def download_chapter
    return render 'hyrax/base/unauthorized', status: :unauthorized unless show?
    epub = EPub::Publication.from_directory(UnpackService.root_path_from_noid(params[:id], 'epub'))
    chapter = EPub::Chapter.from_cfi(epub, params[:cfi])
    rendered_pdf = Rails.cache.fetch(pdf_cache_key(params[:id], chapter.title), expires_in: 30.days) do
      pdf = chapter.pdf
      pdf.render
    end
    CounterService.from(self, @presenter).count(request: 1, section_type: "Chapter", section: chapter.title)
    send_data rendered_pdf, type: "application/pdf", disposition: "inline"
  end

  def download_section
    return render 'hyrax/base/unauthorized', status: :unauthorized unless show?
    epub = EPub::Publication.from_directory(UnpackService.root_path_from_noid(params[:id], 'epub'))
    section = EPub::Section.from_cfi(epub, params[:cfi])
    rendered_pdf = Rails.cache.fetch(pdf_cache_key(params[:id], section.title), expires_in: 30.days) do
      pdf = section.pdf
      pdf.render
    end
    CounterService.from(self, @presenter).count(request: 1, section_type: "Chapter", section: section.title)
    send_data rendered_pdf, type: "application/pdf", disposition: "inline"
  end

  def pdf_cache_key(id, chapter_title)
    "pdf:" +
      Digest::MD5.hexdigest(chapter_title) +
      id +
      @presenter.date_modified.to_s
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
      @subscriber = nil
      clear_session_show
      if access?
        set_session_show
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

    def show?
      if session[:show_set].present?
        session[:show_set].include?(params[:id])
      else
        false
      end
    end

    def set_session_show
      session[:show_set] ||= []
      session[:show_set].shift if session[:show_set].length > 9
      clear_session_show
      session[:show_set] << params[:id]
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
