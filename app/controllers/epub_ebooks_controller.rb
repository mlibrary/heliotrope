# frozen_string_literal: true

class EpubEbooksController < CheckpointController
  include IrusAnalytics::Controller::AnalyticsBehaviour

  protect_from_forgery except: :file
  before_action :setup

  def show
    raise NotAuthorizedError unless EbookReaderOperation.new(current_actor, @epub_ebook).allowed?

    @parent_presenter = @presenter.parent
    raise(NotAuthorizedError, "Orphan Electronic Publication") if @parent_presenter.blank?

    @title = @parent_presenter.page_title
    @citable_link = @parent_presenter.citable_link
    @subdomain = @parent_presenter.subdomain
    @back_link = if params[:publisher].present?
                   URI.join(main_app.root_url, params[:publisher]).to_s
                 else
                   @parent_presenter.catalog_url
                 end
    @ebook_download_presenter = EBookDownloadPresenter.new(@parent_presenter, current_ability, current_actor)
    @search_url = main_app.search_epub_ebook_url(@noid, q: '').gsub!(/locale=en&/, '')

    unless Rails.env.test?
      map_file_doc = ActiveFedora::SolrService.query("+has_model_ssim:FileSet AND +monograph_id_ssim:#{Rails.configuration.princesse_de_cleves_monograph_noid} AND +resource_type_tesim:interactive+map", rows: 1)&.first
    else
      map_file_doc = nil
    end
    @map_file_presenter = map_file_doc.present? ? Hyrax::FileSetPresenter.new(map_file_doc, current_ability).embed_link : nil

    CounterService.from(self, @presenter).count(request: 1)
    send_irus_analytics_request
    render layout: false
  end

  def file
    return head :no_content unless EbookReaderOperation.new(current_actor, @epub_ebook).allowed?

    epub = EPub::Publication.from_directory(UnpackService.root_path_from_noid(@noid, 'epub'))
    filename = params[:file] + '.' + params[:format]

    file = epub.file(filename)
    file = file.to_s.sub(/releases\/\d+/, "current")
    response.headers['X-Sendfile'] = file

    send_file file
  rescue StandardError => e
    Rails.logger.info("EpubEbooksController.file raised #{e}")
    head :no_content
  end

  # this is almost completly the same as EPubsController#search
  def search
    return head :not_found unless EbookReaderOperation.new(current_actor, @epub_ebook).allowed?

    if Rails.env.development?
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'GET'
      headers['Access-Control-Request-Method'] = '*'
    end

    query = params[:q] || ''
    # due to performance issues, must have 3 or more characters to search
    return render json: { q: query, search_results: [] } if query.length < 3

    log = EpubSearchLog.create(noid: @noid, query: query, user: current_actor.email, press: @presenter.parent.subdomain, session_id: session.id)
    start = (Time.now.to_f * 1000.0).to_i

    epub = EPub::Publication.from_directory(UnpackService.root_path_from_noid(@noid, 'epub'))

    # no query caching for platform_admins so they can better test performance issues, HELIO-4082
    results = if current_actor.platform_admin?
                epub.search(query)
              else
                Rails.cache.fetch(search_cache_key(@noid, query), expires_in: 30.days) { epub.search(query) }
              end

    finish = (Time.now.to_f * 1000.0).to_i
    log.update(time: finish - start, hits: results[:search_results].count, search_results: results)

    render json: results
  rescue StandardError => e
    Rails.logger.error "EpubEbooksController.search raised #{e}"
    head :not_found
  end

  def search_cache_key(id, query)
    "epub:" +
      Digest::MD5.hexdigest(query) +
      id +
      @presenter.date_modified.to_s
  end

  def item_identifier_for_irus_analytics
    CatalogController.blacklight_config.oai[:provider][:record_prefix] + ":" + @parent_presenter.id
  end

    private

      def setup
        @noid = params[:id]
        raise(PageNotFoundError, "Princesse de Cleves NOID not valid!") unless ValidationService.valid_noid?(@noid)
        @presenter = Hyrax::PresenterFactory.build_for(ids: [@noid], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
        @epub_ebook = Sighrax.from_presenter(@presenter)
        raise(NotAuthorizedError, "Non Electronic Publication") unless @epub_ebook.is_a?(Sighrax::EpubEbook)
      end
end
