# frozen_string_literal: true

class EpubEbooksController < CheckpointController
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
    CounterService.from(self, @presenter).count(request: 1)
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

  def search
    query = params[:q] || ''
    return render json: { q: query, search_results: [] } unless EbookReaderOperation.new(current_actor, @epub_ebook).allowed?

    render json: { q: query, search_results: [] }
  end

    private

      def setup
        @noid = params[:id]
        raise(PageNotFoundError, "Princesse de Cleves NOID not equal!") unless @noid == Settings.princesse_de_cleves_noid
        raise(PageNotFoundError, "Princesse de Cleves NOID not valid!") unless ValidationService.valid_noid?(@noid)
        @presenter = Hyrax::PresenterFactory.build_for(ids: [@noid], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first
        @epub_ebook = Sighrax.from_presenter(@presenter)
        raise(NotAuthorizedError, "Non Electronic Publication") unless @epub_ebook.is_a?(Sighrax::EpubEbook)
      end
end
