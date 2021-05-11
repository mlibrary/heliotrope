# frozen_string_literal: true

class EbooksController < CheckpointController
  include PdfProtection::CoverPage

  before_action :setup

  def download
    raise NotAuthorizedError unless EbookDownloadOperation.new(current_actor, @ebook).allowed?
    return redirect_to(hyrax.download_path(params[:id])) unless @ebook.watermarkable? && @ebook.publisher.watermark?

    begin
      parent_presenter = Sighrax.hyrax_presenter(@ebook.parent)
      raise "Monograph #{parent_presenter.id} is missing metadata for cover page" unless parent_presenter.citations_ready?

      CounterService.from(self, Sighrax.hyrax_presenter(@ebook)).count(request: 1)
      send_data watermark_pdf(@ebook, parent_presenter), type: 'application/pdf', filename: @ebook.filename
    rescue StandardError => e
      Rails.logger.error "EbooksController.download raised #{e}"
      head :no_content
    end
  end

  private

    def setup
      # @entity is referenced in PdfProtection::CoverPage.cache_key_timestamp()
      @entity = @ebook = Sighrax.from_noid(params[:id])
    end
end
