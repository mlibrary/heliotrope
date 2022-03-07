# frozen_string_literal: true

class EbooksController < CheckpointController
  include Watermark::Watermarkable
  include IrusAnalytics::Controller::AnalyticsBehaviour

  before_action :setup
  before_action :wayfless_redirect_to_shib_login, only: %i[download]

  def download
    raise NotAuthorizedError unless EbookDownloadOperation.new(current_actor, @ebook).allowed?
    return redirect_to(hyrax.download_path(params[:id])) unless @ebook.watermarkable? && @ebook.publisher.watermark?

    # we'll send the linearized file in all cases, leave Fedora out of it. They should always exist, and do right now.
    ebook_file_path = UnpackService.root_path_from_noid(params[:id], 'pdf_ebook') + '.pdf'
    run_watermark_checks(ebook_file_path)

    begin
      send_irus_analytics_request
      CounterService.from(self, Sighrax.hyrax_presenter(@ebook)).count(request: 1)
      send_data watermark_pdf(@ebook, @ebook.filename, ebook_file_path), type: 'application/pdf', filename: @ebook.filename
    rescue StandardError => e
      Rails.logger.error "EbooksController.download raised #{e}"
      head :no_content
    end
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
