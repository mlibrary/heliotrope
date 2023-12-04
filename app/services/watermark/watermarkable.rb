# frozen_string_literal: true

require 'open3'

module Watermark
  module Watermarkable
    extend ActiveSupport::Concern
    include Hyrax::CitationsBehavior
    include Skylight::Helpers

    def run_watermark_checks(file_path)
      # checking `citations_ready?` may seem worthwhile, but we can occasionally have public "pre-publication content"...
      # on Fulcrum missing, e.g. the publication year (especially in EBC), that might stay incomplete for weeks.
      # I'm leaving the line and comment here as a reminder of this.
      # raise "Monograph #{parent_presenter.id} is missing metadata for watermark" unless parent_presenter.citations_ready?
      raise "PDF file #{file_path} does not exist" unless File.exist?(file_path)
      raise "PDFtk not present on machine" unless system("which pdftk > /dev/null 2>&1")
    end

    instrument_method
    def watermark_pdf(entity, title, file_path = nil, chapter_index = nil)
      fmt = watermark_formatted_text

      Rails.cache.fetch(cache_key(entity, fmt.to_s + title.to_s + chapter_index.to_s), expires_in: 30.days) do
        watermark_pdfs_dir = File.join(Settings.scratch_space_path, 'watermark_pdfs')
        FileUtils.mkdir_p(watermark_pdfs_dir) if !Dir.exist?(watermark_pdfs_dir)

        suffix = Random.rand(999_999_999).to_s.rjust(9, "0")
        # for cleanup a nightly cron can delete older "watermark_pdf_*" files inside `watermark_pdfs_dir`
        stamp_file_path = File.join(watermark_pdfs_dir, "watermark_pdf_stamp_#{suffix}.pdf")
        create_watermark_pdf(fmt, stamp_file_path)
        stamped_file_path = File.join(watermark_pdfs_dir, "watermark_pdf_stamped_#{suffix}.pdf")

        # HELIO-4508 version 3.2.2 of pdftk can't do hyperlinks in watermark stamps
        # command = "pdftk #{file_path} stamp #{stamp_file_path} output #{stamped_file_path}"
        # qpdf can add watermakrks with hyperlinks so we'll use that.
        # qpdf sends warnings to stderr (and there are a lot of warnings) so --warning-exit-0 to send an exit code 0 for warnings
        # command = "qpdf --warning-exit-0 --overlay #{stamp_file_path} --repeat=1 -- #{file_path} #{stamped_file_path}"
        # Unfortunatly circle ci is stuck on verion 9 of qpdf so we can't use --warning-exit-0 yet. See HELIO-4508
        command = "qpdf --overlay #{stamp_file_path} --repeat=1 -- #{file_path} #{stamped_file_path}"

        run_command_with_timeout(command, 120) # Timout in seconds see HELIO-4530, HELIO-4534
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
      # We don't really know how wide things should be, we just want them less then the total width of the pdf margin box
      # inside of an A3. But, that box can be different depending on the pdf (I think).
      # So it's trial and error hence the magic width number which is used to add newlines inside really long text
      # values that need to be broken up in order to fit in the box.
      magic_max_char_width_number = 160 # 150
      wrapped = wrap_text(struct[:author] + '___' + struct[:title], magic_max_char_width_number)
      parts = wrapped.split('___')
      fmt_txt =  []
      fmt_txt << { text: parts[0] }
      fmt_txt << { text: parts[1], styles: [:italic] }

      link_citation(wrap_text(struct[:publisher], magic_max_char_width_number)).each do |result|
        fmt_txt << result
      end

      if parent_presenter.license?
        fmt_txt << { text: "\n" }
        fmt_txt << {
                     text: parent_presenter.license_abbreviated,
                     link: parent_presenter.solr_document.license.first.sub('http:', 'https:')
                   }
      end
      fmt_txt << { text: "\nDownloaded on behalf of #{request_origin}" }
      fmt_txt
    end

    def link_citation(publisher_string)
      citation = []
      citation << { text: "\n" }
      if /https/.match?(publisher_string)
        match = /^.*(https:\/\/.*).$/.match(publisher_string)
        link = match[1]
        text = publisher_string.gsub("#{link}", "")
        text.chomp!(".") # remove that trailing period
        citation << { text: text }
        citation << { link: link, text: link }
        citation << { text: "." }
      else
        citation << { text: publisher_string }
      end

      citation
    end

    instrument_method
    def create_watermark_pdf(formatted_text, output_file_path)
      size = 10 # font size
      text = formatted_text.pluck(:text).join('')
      height = (text.lines.count + 1) * size # height of the bounding box
      width = 0 # width of the bounding box
      text.lines.each do |line|
        width = (width < line.size) ? line.size : width
      end
      # This is a guess. Font width and spacing vs. font height is complicated.
      # PDF margins are variable. This is trail and error.
      # The number below was 2, and some letters probably are half as wide as they are tall, but not all of them.
      # We're not using a monospace font so this is not consistent.
      width *= (size / 2.1)

      # we are no longer examining the page size and the stamp auto-sizing of command line tools like qpdf or pdftk...
      # is neater if the stamp is being shrunk, keeping the watermark in what would be considered the "footer" area.
      # Hence A3 with a text size of 10 on the stamp. Cause we have a variety of page sizes but none should be...
      # larger than A3.
      pdf = Prawn::Document.new(page_size: 'A3') do
        font_families.update("OpenSans" => {
            normal: Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Regular.ttf'),
            italic: Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Italic.ttf'),
        })

        # Uncomment these to help see what's going on with layout
        # stroke_axis
        # stroke_circle [0, 0], 10

        # bounding_box_height is used to position the watermark based on number of lines in the watermark, keeping it low on the page
        # without falling off while not obscuring the acutal book text.
        # A pdf with no license and no long titles or other text is normally 3 lines. This is most of them.
        # With a license it's 4 lines.
        # With long text it could be broken up into an unknown number, but this is very unusual.
        bounding_box_height = if text.lines.count <= 4
                                size
                              elsif text.lines.count == 5
                                size * 2
                              elsif text.lines.count == 6
                                size * 3
                              else
                                size * 4
                              end

        font('OpenSans', size: size) do
          bounding_box([0, bounding_box_height], width: width, height: height) do
            # Uncomment to help see layout
            # stroke_bounds
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

    instrument_method
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

        # qpdf fails all the time because it considers warnings to be errors. It writes warnings to stderr which
        # is kind of annoying. In newer versions, 10+ I think, you can pass the "-warning-exit-0" flag which stops this from happening.
        # Unfortunatly even though we have 10+ in development and production, we don't have it in circle ci.
        # See HELIO-4508. For now we do some bad string matching to see if this is a "real" error
        # Error warnings will look like this:
        #
        # "WARNING: /home/sethajoh/apps/heliotrope/spec/fixtures/0.pdf: reported number of objects (17) is not one plus the highest object number (134)\n
        # qpdf: operation succeeded with warnings; resulting file may have some problems\n"

        return if err.match?("warning") && err.match("operation succeeded")
        raise "Unable to execute command \"#{cmd}\"\n#{err}\n#{out}" unless exit_status.success?
      end
    end
  end
end
