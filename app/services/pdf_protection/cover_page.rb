# frozen_string_literal: true

module PdfProtection
  module CoverPage
    extend ActiveSupport::Concern
    include Hyrax::CitationsBehavior

    def watermark_pdf(entity, presenter, file = nil, chapter_index = nil)
      # I would prefer that this method be the only place where the existence of cover page metadata is verified,...
      # but because this watermarking is done in controllers as data is sent, the controllers need to check this...
      # for now. Meaning this should never happen here and is a fallback. Future refactoring potential.
      raise "Monograph #{presenter.id} is missing metadata for cover page" unless presenter.citations_ready?

      cover_page_text = { title: presenter.title,
                          author: presenter.authors(false), # full creator names, not reversed and w/o contributors
                          copyright: presenter.date_created.first + ' © ' + presenter.copyright_holder,
                          citation: export_as_chicago_citation(presenter)
                                        .sub('<span class="citation-author">', '').sub('</span>', '')
                                        .sub('<i class="citation-title">', '<i>'),
                          download_message: "This content was downloaded on #{Time.zone.now.strftime('%e %b %Y').strip} from University of Michigan, Ann Arbor"
      }

      # as the cover page has today's date, the cached file is invalid after 1 day
      Rails.cache.fetch(cache_key(entity, cover_page_text.to_s + chapter_index.to_s), expires_in: 1.day) do
        content = file.presence || entity.content
        logo = entity&.parent&.publisher&.press&.logo_path&.file&.file || Rails.root.join('app', 'assets', 'images', 'fulcrum-white-50px.png')

        pdf = CombinePDF.parse(content, allow_optional_content: true)
        # https://github.com/boazsegev/combine_pdf/blob/b966e703fd897ff50832d3823e74791099b82ca3/lib/combine_pdf.rb#L84
        first_page = pdf.pages[0]
        mediabox = first_page[:CropBox] || first_page[:MediaBox] # copy page size
        # mediabox seems to contain something like [x0, y0, x1, y1] at this point
        cover = cover_page(cover_page_text, mediabox[2] - mediabox[0], mediabox[3] - mediabox[1], logo)
        pdf >> CombinePDF.parse(cover) # the >> operator adds pages at the beginning

        # https://github.com/boazsegev/combine_pdf/issues/188#issuecomment-831377639
        pdf.to_pdf({ keywords: "#{ActionView::Base.full_sanitizer.sanitize(cover_page_text[:citation])} #{cover_page_text[:download_message]} on behalf of #{request_origin}".encode('utf-16') })
      end
    end

    def cache_key_timestamp
      Rails.logger.info "@entity.noid: #{@entity.noid}"
      ActiveFedora::SolrService.query("{!terms f=id}#{@entity.noid}", rows: 1).first['timestamp']
    rescue StandardError => _e
      ''
    end

    def request_origin
      @request_origin ||= current_institution&.name || request.remote_ip
    end

    def cover_page(cover_page_text, x, y, logo)
      pdf = Prawn::Document.new(page_size: [x, y]) do
        font_families.update("OpenSans" => {
            normal: Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Regular.ttf'),
            italic: Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Italic.ttf'),
        })

        image logo, position: :center, width: x/3
        pad(50) { stroke_horizontal_rule }
        font 'OpenSans'
        font_size 20

        indent(20) do
          text cover_page_text[:title]
          move_down 20
          font_size 16
          text cover_page_text[:author]
          move_down 30
          text cover_page_text[:copyright]
          font_size 15
          move_down 80
          text cover_page_text[:citation], inline_format: true
          move_down 150
        end

        pad(15) { stroke_horizontal_rule }

        indent(10) do
          text cover_page_text[:download_message]
        end
      end
      pdf.render
    end

    def cache_key(entity, text)
      "pdfwm:#{entity.noid}-#{Digest::MD5.hexdigest(text)}-#{cache_key_timestamp}"
    end
  end
end
