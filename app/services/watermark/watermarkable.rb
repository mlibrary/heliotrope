# frozen_string_literal: true

require 'open3'

module Watermark
  module Watermarkable
    extend ActiveSupport::Concern
    include Hyrax::CitationsBehavior

    def run_watermark_checks(file_path)
      # checking `citations_ready?` may seem worthwhile, but we can occasionally have public "pre-publication content"...
      # on Fulcrum missing, e.g. the publication year (especially in EBC), that might stay incomplete for weeks.
      # I'm leaving the line and comment here as a reminder of this.
      # raise "Monograph #{parent_presenter.id} is missing metadata for watermark" unless parent_presenter.citations_ready?
      raise "PDF file #{file_path} does not exist" unless File.exist?(file_path)
      raise "PDFtk not present on machine" unless system("which pdftk > /dev/null 2>&1")
    end

    def watermark_pdf(entity, title, file_path = nil, chapter_index = nil)
      fmt = watermark_formatted_text

      Rails.cache.fetch(cache_key(entity, fmt.to_s + title.to_s + chapter_index.to_s), expires_in: 30.days) do
        # I think a nightly cron to clean up "watermark_pdf_*" files older than a couple of hours will work
        suffix = Random.rand(999_999_999).to_s.rjust(9, "0")
        stamp_file_path = Rails.root.join('tmp', "watermark_pdf_stamp_#{suffix}.pdf")
        create_watermark_pdf(fmt, stamp_file_path)
        stamped_file_path = Rails.root.join('tmp', "watermark_pdf_stamped_#{suffix}.pdf")

        command = "pdftk #{file_path} stamp #{stamp_file_path} output #{stamped_file_path}"

        run_command_with_timeout(command, 45) # hopefully 45 seconds is enough for a large PDF at busy times
        IO.binread(stamped_file_path)
      end
    end

    def parent_presenter
      @parent_presenter ||= Sighrax.hyrax_presenter(@entity.parent)
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
    def watermark_formatted_text
      struct = export_as_mla_structure(parent_presenter)
      wrapped = wrap_text(struct[:author] + '___' + struct[:title], 150)
      parts = wrapped.split('___')
      [{ text: parts[0] },
       { text: parts[1], styles: [:italic] },
       { text: "\n" + wrap_text(struct[:publisher], 150) },
       { text: "\nDownloaded on behalf of #{request_origin}" }
      ]
    end

    def create_watermark_pdf(formatted_text, output_file_path)
      size = 10
      text = formatted_text.map { |t| t[:text] }.join('')
      height = (text.lines.count + 1) * size
      width = 0
      text.lines.each do |line|
        width = (width < line.size) ? line.size : width
      end
      width *= (size / 2.0)
      # we are no longer examining the page size and the stamp auto-sizing of command line tools like qpdf or pdftk...
      # is neater if the stamp is being shrunk, keeping the watermark in what would be considered the "footer" area.
      # Hence A3 with a text size of 10 on the stamp. Cause we have a variety of page sizes but none should be...
      # larger than A3.
      pdf = Prawn::Document.new(page_size: 'A3') do
        font_families.update("OpenSans" => {
            normal: Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Regular.ttf'),
            italic: Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Italic.ttf'),
        })

        font('OpenSans', size: size) do
          bounding_box([0, size], width: width, height: height) do
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
      pdf.render_file(output_file_path)
    end

    def cache_key(entity, text)
      "pdfwm:#{entity.noid}-#{Digest::MD5.hexdigest(text)}-#{cache_key_timestamp}"
    end

    def run_command_with_timeout(cmd, time_limit)
      Open3.popen3(cmd) do |_, stdout, stderr, wait_thr|
        out = ''
        err = ''
        exit_status = 0
        pid = 0
        begin
          Timeout.timeout(time_limit) do
            pid = wait_thr.pid
            out = stdout.read
            err = stderr.read
            exit_status = wait_thr.value
            Process.wait(pid)
          end
        rescue Errno::ECHILD
        rescue Timeout::Error # "execution expired"
          Process.kill('HUP', pid)
          fail
        end
        raise "Unable to execute command \"#{cmd}\"\n#{err}\n#{out}" unless exit_status.success?
      end
    end
  end
end
