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

    # we'll send the linearized file in all cases, leave Fedora out of it. They should always exist, and do right now.
    ebook_file_path = UnpackService.root_path_from_noid(params[:id], 'pdf_ebook') + '.pdf'

    watermarker = WatermarkService.new(
      ebook: @ebook,
      title: @ebook.filename,
      file_path: ebook_file_path,
      request: request,
      current_institution: current_institution,
      download_path: download_ebook_path(params[:id]),
      chapter_index: nil
    )

    begin
      send_irus_analytics_request
      CounterService.from(self, Sighrax.hyrax_presenter(@ebook)).count(request: 1)
      if watermarker.cached?
        send_data watermarker.send_watermarked_pdf, type: 'application/pdf', filename: @ebook.filename
      else
        # This should never happen, this should all happen in a job.
        # But if something went wrong, watermake and send the pdf this way
        send_data watermarker.build_and_send_watermarked_pdf, type: 'application/pdf', filename: @ebook.filename
      end
    rescue StandardError => e
      Rails.logger.error "EbooksController.download raised #{e}"
      head :no_content
    end
  end

  # POST called by ajax
  def watermark
    broadcast_finished("EbookDownloadOperation not allowed") unless EbookDownloadOperation.new(current_actor, @ebook).allowed?
    braodcast_finished("Ebook not watermarkable or publisher not set up") unless @ebook.watermarkable? && @ebook.publisher.watermark?

    watermarker = WatermarkService.new(
      ebook: @ebook,
      title: @ebook.filename,
      file_path: UnpackService.root_path_from_noid(params[:id], 'pdf_ebook') + '.pdf',
      request: request,
      current_institution: current_institution,
      download_path: download_ebook_path(params[:id]),
      chapter_index: nil
    )

    broadcast_finished("Watermarked book is already cached") if watermarker.cached?
    watermarker.create_watermark_pdf unless File.exist? watermarker.stamp_file_path
    watermarker.run_job
    head :ok
  end

  def broadcast_finished(message)
    ActionCable.server.broadcast "long_running_requests_channel_#{request.session.id}", {
      message: message,
      download_url: download_ebook_path(params[:id])
    }
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
