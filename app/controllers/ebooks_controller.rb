# frozen_string_literal: true

class EbooksController < CheckpointController
  include IrusAnalytics::Controller::AnalyticsBehaviour
  include Skylight::Helpers
  include Rails.application.routes.url_helpers

  before_action :setup
  before_action :wayfless_redirect_to_shib_login, only: %i[download]

  instrument_method
  def download
    raise NotAuthorizedError unless EbookDownloadOperation.new(current_actor, @ebook).allowed?
    return redirect_to(hyrax.download_path(params[:id])) unless @ebook.watermarkable? && @ebook.publisher.watermark?

    # we'll send the linearized on disk file in all cases, leave Fedora out of it.
    ebook_file_path = UnpackService.root_path_from_noid(params[:id], 'pdf_ebook') + '.pdf'

    watermarker = WatermarkService.new(@ebook, @ebook.filename, ebook_file_path, request_origin)

    if watermarker.cached?
      send_irus_analytics_request
      CounterService.from(self, Sighrax.hyrax_presenter(@ebook)).count(request: 1)
      send_data watermarker.watermarked_pdf, type: 'application/pdf', filename: @ebook.filename
    else
      watermarker.run_job
      redirect_to(job_status_path(watermarker.status.id, press_id: @ebook.publisher.press.id, download_redirect: download_ebook_path(params[:id])))
    end


    # begin
    #   send_irus_analytics_request
    #   CounterService.from(self, Sighrax.hyrax_presenter(@ebook)).count(request: 1)
    #   send_data watermarker.watermark_pdf, type: 'application/pdf', filename: @ebook.filename
    # rescue StandardError => e
    #   Rails.logger.error "EbooksController.download raised #{e}"
    #   Rails.logger.error e.backtrace.join("\n")
    #   head :no_content
    # end
  end

  def item_identifier_for_irus_analytics
    # return the OAI identifier FOR THE WORK, not the file_set. IRUS or more specificaly OAI doesn't
    # really know about FileSets. HELIO-4143, HELIO-3778
    CatalogController.blacklight_config.oai[:provider][:record_prefix] + ":" + Sighrax.hyrax_presenter(@ebook).parent.id
  end

  private

    def setup
      @entity = @ebook = Sighrax.from_noid(params[:id])
    end
end
