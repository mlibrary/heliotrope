# frozen_string_literal: true

class EPubsController < CheckpointController
  protect_from_forgery except: :file
  before_action :set_presenter, only: %i[show download_chapter download_interval search access]
  before_action :set_access_presenters, only: %i[access]
  before_action :set_policy, only: %i[show download_chapter download_interval]
  before_action :set_show, only: %i[show download_chapter download_interval]

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

    @ebook_download_presenter = EBookDownloadPresenter.new(@monograph_presenter, current_ability, current_actor)

    @use_archive = if File.exist?(File.join(UnpackService.root_path_from_noid(params[:id], 'epub'), params[:id] + ".sm.epub"))
                     true
                   else
                     false
                   end

    @press = Press.where(subdomain: @subdomain).first
    @component = component

    CounterService.from(self, @presenter).count(request: 1)

    log_share_link_use

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
    if Rails.env.development?
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

  def download_interval
    return render 'hyrax/base/unauthorized', status: :unauthorized unless show?
    publication = EPub::Publication.from_directory(UnpackService.root_path_from_noid(params[:id], 'epub'))
    interval = EPub::Interval.from_rendition_cfi_title(publication.rendition, params[:cfi], params[:title])
    rendered_pdf = Rails.cache.fetch(pdf_cache_key(params[:id], interval.title), expires_in: 30.days) do
      pdf = EPub::Marshaller::PDF.from_publication_interval(publication, interval)
      pdf.document.render
    end
    CounterService.from(self, @presenter).count(request: 1, section_type: "Chapter", section: interval.title)
    send_data rendered_pdf, type: "application/pdf", disposition: "inline"
  end

  def pdf_cache_key(id, chapter_title)
    "pdf:" +
      Digest::MD5.hexdigest(chapter_title) +
      id +
      @presenter.date_modified.to_s
  end

  def share_link
    presenter = Hyrax::PresenterFactory.build_for(ids: [params[:id]], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
    subdomain = presenter.monograph.subdomain
    if Press.where(subdomain: subdomain).first&.allow_share_links?
      expire = Time.now.to_i + 48 * 3600 # 48 hours
      token = JsonWebToken.encode(data: params[:id], exp: expire)
      ShareLinkLog.create(ip_address: request.ip,
                          institution: current_institutions.map(&:name).join("|"),
                          press: subdomain,
                          title: presenter.monograph.title,
                          noid: presenter.id,
                          token: token,
                          action: 'create')
      render plain: Rails.application.routes.url_helpers.epub_url(params[:id], share: token)
    else
      head :no_content
    end
  end

  private

    def log_share_link_use
      return if @share_link.nil?
      ShareLinkLog.create(ip_address: request.ip,
                          institution: current_institutions.map(&:name).join("|"),
                          press: @subdomain,
                          title: @monograph_presenter.title,
                          noid: @presenter.id,
                          token: @share_link,
                          action: 'use')
    end

    def set_presenter
      @presenter = Hyrax::PresenterFactory.build_for(ids: [params[:id]], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
      unless @presenter.present? && @presenter.epub? # rubocop:disable Style/GuardClause
        Rails.logger.info("EPubsController.set_presenter(#{params[:id]}) is not an EPub.")
        render 'hyrax/base/unauthorized', status: :unauthorized
      end
    end

    def set_access_presenters
      @monograph_presenter = nil
      if @presenter.parent.present?
        @monograph_presenter = Hyrax::PresenterFactory.build_for(ids: [@presenter.parent.id], presenter_class: Hyrax::MonographPresenter, presenter_args: current_ability).first
      end
      @institutions = component_institutions
      @products = component_products
    end

    def set_policy
      @policy = EPubPolicy.new(current_actor, Sighrax.factory(@presenter.id), valid_share_link?)
    end

    def set_show
      return if show?
      @subscriber = nil
      clear_session_show
      if access?
        set_session_show
      else
        set_access_presenters
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
      return true if valid_share_link?
      return legacy_access? unless Rails.configuration.e_pub_checkpoint_authorization
      @policy.show?
    end

    def valid_share_link?
      @share_link = params[:share]
      if @share_link.present?
        begin
          decoded = JsonWebToken.decode(@share_link)
          return true if decoded[:data] == params[:id]
        rescue JWT::ExpiredSignature
          return false
        end
      end
      false
    end

    def legacy_access?
      return true if component.blank?
      products = component.products
      return false if products.blank?
      products_lessees = []
      products.each { |product| products_lessees += product.lessees }
      return false if products_lessees.blank?
      identifiers = current_institutions.map(&:identifier)
      identifiers << subscriber.identifier
      lessees = Lessee.where(identifier: identifiers.flatten)
      lessees.any? { |lessee| products_lessees.include?(lessee) }
    end

    def component_institutions
      institutions = []
      component_products.each { |product| institutions += product.institutions }
      institutions.uniq
    end

    def component_products
      return [] if component.blank?
      products = component.products
      return [] if products.blank?
      products
    end

    def component
      @component ||= Component.find_by(noid: @presenter.id)
    end

    def subscriber
      @subscriber ||= OpenStruct.new(identifier: valid_user_signed_in? ? current_user.email : 'anonymous')
    end
end
