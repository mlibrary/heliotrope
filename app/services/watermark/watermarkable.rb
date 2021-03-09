# frozen_string_literal: true

module Watermark
  module Watermarkable
    extend ActiveSupport::Concern
    include Hyrax::CitationsBehavior

    def watermark_pdf(entity, title, size = 6, file = nil, chapter_index = nil)
      fmt = watermark_formatted_text(entity)
      # Cache key based on citation, including the request_origin, plus chapter title if any.
      Rails.cache.fetch(cache_key(entity, fmt.to_s + title.to_s + chapter_index.to_s, size), expires_in: 30.days) do
        content = file.presence || entity.content

        pdf = CombinePDF.parse(content, allow_optional_content: true)
        stamps = {} # Cache of stamps with potentially different media boxes
        pdf.pages.each do |page|
          stamp = stamps[page_box(page).to_s] || CombinePDF.parse(watermark(fmt, size, page_box(page))).pages[0]
          page << stamp
          stamps[page_box(page).to_s] = stamp
        end

        pdf.to_pdf
      end
    end

    # https://wiki.scribus.net/canvas/Talk:PDF_Boxes_:_mediabox,_cropbox,_bleedbox,_trimbox,_artbox
    # "A PDF always has a MediaBox definition. All the other page boxes do not
    # necessarily have to be present within the file."
    def page_box(page)
      page[:TrimBox] ? page[:TrimBox] : page[:MediaBox]
    end

    def watermark_authorship(presenter)
      # presenter.authors can only be missing now if creator itself is blank, which would break citations as well
      presenter.authors? ? CGI.unescapeHTML(presenter.authors(false)) + ', ' : ''
    end

    def cache_key_timestamp
      ActiveFedora::SolrService.query("{!terms f=id}#{@entity.noid}", rows: 1).first['timestamp']
    rescue StandardError => _e
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

    # Returns Prawn::Text::Formatted compatible structure
    def watermark_formatted_text(entity)
      presenter = Sighrax.hyrax_presenter(entity.parent)
      struct = export_as_mla_structure(presenter)
      wrapped = wrap_text(struct[:author] + '___' + struct[:title], 150)
      parts = wrapped.split('___')
      [{ text: parts[0] },
       { text: parts[1], styles: [:italic] },
       { text: "\n" + wrap_text(struct[:publisher], 150) },
       { text: "\nDownloaded on behalf of #{request_origin}" }
      ]
    end

    def watermark(formatted_text, size, media_box)
      text = formatted_text.map { |t| t[:text] }.join('')
      height = (text.lines.count + 1) * size
      width = 0
      text.lines.each do |line|
        width = (width < line.size) ? line.size : width
      end
      width *= (size / 2.0)
      pdf = Prawn::Document.new do
        font_families.update("OpenSans" => {
            normal: Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Regular.ttf'),
            italic: Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Italic.ttf'),
        })

        font('OpenSans', size: size) do
          bounding_box([-20 + media_box[0], -30 + height + media_box[1]], width: width, height: height) do
            transparent(0.5) do
              fill_color "ffffff"
              stroke_color "ffffff"
              fill_rectangle [-size, height + size], width + (2 * size), height + size
              fill_color "000000"
              stroke_color "000000"
              formatted_text formatted_text
            end
          end
        end
      end
      pdf.render
    end

    def cache_key(entity, title, size)
      "pdfwm:#{entity.noid}-#{Digest::MD5.hexdigest(title)}-#{size}-#{cache_key_timestamp}"
    end
  end
end
