# frozen_string_literal: true

module Watermark
  module Watermarkable
    extend ActiveSupport::Concern

    def watermark_pdf(entity, text, size = 7, file = nil)
      Rails.cache.fetch(cache_key(entity, text, size), expires_in: 30.days) do
        content = file.presence || entity.content

        pdf = CombinePDF.parse(content, allow_optional_content: true)
        stamps = {} # Cache of stamps with potentially different media boxes
        pdf.pages.each do |page|
          stamp = stamps[page[:MediaBox].to_s] || CombinePDF.parse(watermark(text, size, page[:MediaBox])).pages[0]
          page << stamp
          stamps[page[:MediaBox].to_s] = stamp
        end

        pdf.to_pdf
      end
    end

    def watermark_authorship(presenter)
      # presenter.authors can only be missing now if creator itself is blank, which would break citations as well
      presenter.authors? ? CGI.unescapeHTML(presenter.authors(false)) + ', ' : ''
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

    def watermark(text, size, media_box)
      height = (text.lines.count + 1) * size
      width = 0
      text.lines.each do |line|
        width = (width < line.size) ? line.size : width
      end
      width *= (size / 2.0)
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

    def cache_key(entity, text, size)
      "#{entity.noid}-#{Digest::MD5.hexdigest(text)}-#{size}-#{cache_key_timestamp}"
    end
  end
end
