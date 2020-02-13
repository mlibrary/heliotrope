# frozen_string_literal: true

class EbooksController < CheckpointController
  include Watermark::Watermarkable

  before_action :setup

  def download
    raise NotAuthorizedError unless @policy.download?
    return redirect_to(hyrax.download_path(params[:id])) unless Sighrax.watermarkable?(@entity) && @press_policy.watermark_download?
    begin
      presenter = Sighrax.hyrax_presenter(@entity.parent)
      text = <<~WATERMARK
          #{wrap_text(watermark_authorship(presenter) + CGI.unescapeHTML(presenter.title), 100)}
          #{presenter.date_created.first}. #{presenter.publisher.first}
          Downloaded on behalf of #{request_origin}
      WATERMARK

      CounterService.from(self, Sighrax.hyrax_presenter(@entity)).count(request: 1)
      send_data watermark_pdf(@entity, text), type: @entity.media_type, filename: @entity.filename
    rescue StandardError => e
      Rails.logger.error "EbooksController.download raised #{e}"
      head :no_content
    end
  end

  private

    def setup
      @entity = Sighrax.from_noid(params[:id])
      @policy = Sighrax.policy(current_actor, @entity)
      @press = Sighrax.press(@entity)
      @press_policy = PressPolicy.new(current_actor, @press)
    end
end
