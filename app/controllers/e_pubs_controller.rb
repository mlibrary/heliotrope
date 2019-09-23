# frozen_string_literal: true

class EPubsController < CheckpointController
  protect_from_forgery except: :file
  before_action :setup

  def show # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return redirect_to epub_access_url unless @policy.show?

    @title = @presenter.parent.present? ? @presenter.parent.page_title : @presenter.page_title
    @citable_link = @presenter.citable_link
    @back_link = params[:publisher].present? ? URI.join(main_app.root_url, params[:publisher]).to_s : main_app.monograph_catalog_url(@presenter.monograph_id)
    @subdomain = @presenter.parent.subdomain
    @monograph_presenter = @presenter.parent

    @ebook_download_presenter = EBookDownloadPresenter.new(@monograph_presenter, current_ability, current_actor)

    if @entity.is_a?(Sighrax::ElectronicPublication)
      @search_url = main_app.epub_search_url(@noid, q: '').gsub!(/locale=en&/, '')
      @use_archive = if File.exist?(File.join(UnpackService.root_path_from_noid(@noid, 'epub'), @noid + ".sm.epub"))
                       true
                     else
                       false
                     end
    end

    @press = Press.where(subdomain: @subdomain).first
    @component = component

    CounterService.from(self, @presenter).count(request: 1)

    log_share_link_use

    if @entity.is_a?(Sighrax::ElectronicPublication)
      render layout: false
    elsif @entity.is_a?(Sighrax::PortableDocumentFormat)
      render 'e_pubs/show_pdf', layout: false
    else
      return head :not_found
    end
  end

  def file
    return head :no_content unless @policy.show?

    if @entity.is_a?(Sighrax::ElectronicPublication)
      epub = EPub::Publication.from_directory(UnpackService.root_path_from_noid(@noid, 'epub'))
      filename = params[:file] + '.' + params[:format]

      file = epub.file(filename)
      file = file.to_s.sub(/releases\/\d+/, "current")
      response.headers['X-Sendfile'] = file

      send_file file
    elsif @entity.is_a?(Sighrax::PortableDocumentFormat)
      send_data @presenter.file.content, filename: @presenter.label, type: "application/pdf", disposition: "inline"
    end
  rescue StandardError => e
    Rails.logger.info("EPubsController.file raised #{e}")
    head :no_content
  end

  def access
    @monograph_presenter = @presenter.parent
    @institutions = component_institutions
    @products = component_products
    CounterService.from(self, @presenter).count(request: 1, turnaway: "No_License")
  end

  def search
    return head :not_found unless @policy.show?

    if Rails.env.development?
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'GET'
      headers['Access-Control-Request-Method'] = '*'
    end

    query = params[:q] || ''
    # due to performance issues, must have 3 or more characters to search
    return render json: { q: query, search_results: [] } if query.length < 3
    results = Rails.cache.fetch(search_cache_key(@noid, query), expires_in: 30.days) do
      epub = EPub::Publication.from_directory(UnpackService.root_path_from_noid(@noid, 'epub'))
      epub.search(query)
    end
    render json: results
  rescue StandardError => e
    Rails.logger.error "EPubsController.search raised #{e}"
    head :not_found
  end

  def download_chapter
    return head :no_content unless @policy.show?

    epub = EPub::Publication.from_directory(UnpackService.root_path_from_noid(@noid, 'epub'))
    cfi = params[:cfi]
    chapter = EPub::Chapter.from_cfi(epub, cfi)

    return head :no_content if chapter.is_a?(EPub::ChapterNullObject)

    rendered_pdf = Rails.cache.fetch(pdf_cache_key(@noid, chapter.title), expires_in: 30.days) do
      pdf = chapter.pdf
      pdf.render
    end
    CounterService.from(self, @presenter).count(request: 1, section_type: "Chapter", section: chapter.title) if rendered_pdf.present?
    send_data rendered_pdf, type: "application/pdf", disposition: "inline"
  rescue StandardError => e
    Rails.logger.error "EPubsController.download_chapter raised #{e}"
    head :no_content
  end

  def download_interval
    return head :no_content unless @policy.show?

    publication = EPub::Publication.from_directory(UnpackService.root_path_from_noid(@noid, 'epub'))
    cfi = params[:cfi]
    title = params[:title]
    interval = EPub::Interval.from_rendition_cfi_title(publication.rendition, cfi, title)

    return head :no_content if interval.is_a?(EPub::IntervalNullObject)

    rendered_pdf = Rails.cache.fetch(pdf_cache_key(@noid, interval.title), expires_in: 30.days) do
      pdf = EPub::Marshaller::PDF.from_publication_interval(publication, interval)
      pdf.document.render
    end
    CounterService.from(self, @presenter).count(request: 1, section_type: "Chapter", section: interval.title) if rendered_pdf.present?
    send_data rendered_pdf, type: "application/pdf", disposition: "inline"
  rescue StandardError => e
    Rails.logger.error "EPubsController.download_interval raised #{e}"
    head :no_content
  end

  def share_link
    return head :no_content unless @policy.show?

    presenter = Hyrax::PresenterFactory.build_for(ids: [@noid], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
    subdomain = presenter.parent.subdomain
    if Press.where(subdomain: subdomain).first&.allow_share_links?
      expire = Time.now.to_i + 28 * 24 * 3600 # 28 days in seconds
      token = JsonWebToken.encode(data: @noid, exp: expire)
      ShareLinkLog.create(ip_address: request.ip,
                          institution: current_institutions.map(&:name).join("|"),
                          press: subdomain,
                          title: presenter.parent.title,
                          noid: presenter.id,
                          token: token,
                          action: 'create')
      render plain: Rails.application.routes.url_helpers.epub_url(@noid, share: token)
    else
      head :no_content
    end
  rescue StandardError => e
    Rails.logger.error "EPubsController.share_link raised #{e}"
    head :no_content
  end

  private

    def setup
      @noid = params[:id]
      @entity = Sighrax.factory(@noid)
      @parent_noid = @entity.parent.noid
      raise(NotAuthorizedError, "Non Electronic Publication") unless @entity.is_a?(Sighrax::ElectronicPublication) || @entity.is_a?(Sighrax::PortableDocumentFormat)
      @presenter = Hyrax::PresenterFactory.build_for(ids: [@noid], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
      @share_link = params[:share] || session[:share_link]
      session[:share_link] = @share_link
      @policy = EPubPolicy.new(current_actor, @entity, valid_share_link?)
    end

    def log_share_link_use
      return unless valid_share_link?
      ShareLinkLog.create(ip_address: request.ip,
                          institution: current_institutions.map(&:name).join("|"),
                          press: @subdomain,
                          title: @monograph_presenter.title,
                          noid: @noid,
                          token: @share_link,
                          action: 'use')
    end

    def valid_share_link?
      if @share_link.present?
        begin
          decoded = JsonWebToken.decode(@share_link)
          return true if decoded[:data] == @noid
        rescue JWT::ExpiredSignature
          return false
        end
      end
      false
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
      @component ||= Greensub::Component.find_by(noid: @parent_noid)
    end

    def search_cache_key(id, query)
      "epub:" +
        Digest::MD5.hexdigest(query) +
        id +
        @presenter.date_modified.to_s
    end

    def pdf_cache_key(id, chapter_title)
      "pdf:" +
        Digest::MD5.hexdigest(chapter_title) +
        id +
        @presenter.date_modified.to_s
    end
end
