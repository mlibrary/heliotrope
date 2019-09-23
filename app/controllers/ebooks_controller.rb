# frozen_string_literal: true

class EbooksController < CheckpointController
  before_action :setup

  def download
    raise NotAuthorizedError unless @policy.download?
    return redirect_to(hyrax.download_path(params[:id])) unless Sighrax.watermarkable?(@entity) && @press_policy.watermark_download?
    begin
      watermarked = Rails.cache.fetch(cache_key, expires_in: 30.days) do
        presenter = Sighrax.hyrax_presenter(@entity.parent)
        text = <<~WATERMARK
          #{wrap_text(CGI.unescapeHTML(presenter.creator_display) + ', ' + CGI.unescapeHTML(presenter.title), 100)}
          #{presenter.date_created.first}. #{presenter.publisher.first}
          Downloaded on behalf of #{request_origin}
        WATERMARK

        pdf = CombinePDF.parse(@entity.content, allow_optional_content: true)
        stamps = {} # Cache of stamps with potentially different media boxes
        pdf.pages.each do |page|
          stamp = stamps[page[:MediaBox].to_s] || CombinePDF.parse(watermark(text, page[:MediaBox])).pages[0]
          page << stamp
          stamps[page[:MediaBox].to_s] = stamp
        end

        pdf.to_pdf
      end
      send_data watermarked, type: @entity.media_type, filename: @entity.filename
    rescue StandardError => e
      Rails.logger.error "EbooksController.download raised #{e}"
      head :no_content
    end
  end

  private

    def setup
      @entity = Sighrax.factory(params[:id])
      @policy = Sighrax.policy(current_actor, @entity)
      @press = Sighrax.press(@entity)
      @press_policy = PressPolicy.new(current_actor, @press)
    end

    def cache_key
      @entity.noid + '-' +
        Digest::MD5.hexdigest(@entity.resource_token) + '-' +
        Digest::MD5.hexdigest(@entity.parent.title) + '-' +
        Digest::MD5.hexdigest(request_origin) + '-' +
        cache_key_timestamp
    end

    def cache_key_timestamp
      ActiveFedora::SolrService.query("{!terms f=id}#{@entity.noid}", rows: 1).first['timestamp']
    rescue # rubocop:disable Style/RescueStandardError
      ''
    end

    def request_origin
      @request_origin ||= current_institution&.name || request.remote_ip
    end

    def wrap_text(text, max)
      words = text.gsub(/\s+/m, ' ').strip.split(' ')
      lines = ['']
      words.each do |word|
        if lines[-1].length + word.length < max || lines[-1].length.zero?
          lines[-1] += ' ' if lines[-1].length.positive?
          lines[-1] += word
        else
          lines << word
        end
      end
      lines.join("\n")
    end

    def watermark(text, media_box)
      size = 7
      height = (text.lines.count + 1) * size
      width = 0
      text.lines.each do |line|
        width = (width < line.size) ? line.size : width
      end
      width *= (size / 2)
      pdf = Prawn::Document.new do
        Prawn::Font::AFM.hide_m17n_warning = true
        font('Times-Roman', size: size) do
          bounding_box([-20 + media_box[0], 0 + media_box[1]], width: width, height: height) do
            transparent(0.5) do
              fill_color "ffffff"
              stroke_color "ffffff"
              fill_rectangle [-size, height + size], width + (2 * size), height + size
              fill_color "000000"
              stroke_color "000000"
              text text
            end
          end
        end
      end
      pdf.render
    end
end
