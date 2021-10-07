# frozen_string_literal: true

class EbooksController < CheckpointController
  include Watermark::Watermarkable

  before_action :setup
  before_action :wayfless, only: %i[download]

  def download
    raise NotAuthorizedError unless @ebook_download_operation_allowed
    return redirect_to(hyrax.download_path(params[:id])) unless @ebook.watermarkable? && @ebook.publisher.watermark?

    # we'll send the linearized file in all cases, leave Fedora out of it. They should always exist, and do right now.
    ebook_file_path = UnpackService.root_path_from_noid(params[:id], 'pdf_ebook') + '.pdf'
    run_watermark_checks(ebook_file_path)

    begin
      CounterService.from(self, Sighrax.hyrax_presenter(@ebook)).count(request: 1)
      send_data watermark_pdf(@ebook, @ebook.filename, ebook_file_path), type: 'application/pdf', filename: @ebook.filename
    rescue StandardError => e
      Rails.logger.error "EbooksController.download raised #{e}"
      head :no_content
    end
  end

  private

    def setup
      @entity = @ebook = Sighrax.from_noid(params[:id])
      @ebook_download_operation_allowed = EbookDownloadOperation.new(current_actor, @ebook).allowed?
    end

    def wayfless
      wayfless_redirect_to_shib_login unless @ebook_download_operation_allowed
    end
end
