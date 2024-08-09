# frozen_string_literal: true

class WatermarkService
  include Hyrax::CitationsBehavior
  include Skylight::Helpers
  attr_accessor :file_path, :request, :download_path, :stamp_file_path, :stamped_file_path

  def initialize(ebook:, title:, file_path:, request:, current_institution:, download_path:, chapter_index:)
    run_watermark_checks(file_path)

    @ebook = ebook
    @title = title
    @file_path = file_path
    @request = request
    @current_institution = current_institution
    @download_path = download_path
    @chapter_index = chapter_index

    @watermark_formatted_text = watermark_formatted_text
    @cache_key = cache_key

    watermark_pdfs_dir = File.join(Settings.scratch_space_path, 'watermark_pdfs')
    FileUtils.mkdir_p(watermark_pdfs_dir) if !Dir.exist?(watermark_pdfs_dir)
    suffix = Random.rand(999_999_999).to_s.rjust(9, "0")

    @stamp_file_path = File.join(watermark_pdfs_dir, "watermark_pdf_stamp_#{suffix}.pdf")
    @stamped_file_path = File.join(watermark_pdfs_dir, "watermark_pdf_stamped_#{suffix}.pdf")
  end

  def run_watermark_checks(file_path)
    # checking `citations_ready?` may seem worthwhile, but we can occasionally have public "pre-publication content"...
    # on Fulcrum missing, e.g. the publication year (especially in EBC), that might stay incomplete for weeks.
    # I'm leaving the line and comment here as a reminder of this.
    # raise "Monograph #{parent_presenter.id} is missing metadata for watermark" unless parent_presenter.citations_ready?
    raise "PDF file #{file_path} does not exist" unless File.exist?(file_path)
    raise "PDFtk not present on machine" unless system("which pdftk > /dev/null 2>&1")
  end

  def run_job
    opts = {
      file_path: @file_path,
      stamp_file_path: @stamp_file_path,
      stamped_file_path: @stamped_file_path,
      session_id: @request.session.id.to_s,
      cache_key: cache_key,
      download_path: @download_path
    }

    WatermarkJob.perform_later(opts)
  end

  def send_watermarked_pdf
    Rails.cache.read(@cache_key)
  end

  def cached?
    Rails.cache.exist?(@cache_key)
  end

  # Returns Prawn::Text::Formatted compatible structure
  def watermark_formatted_text
    struct = export_as_mla_structure(parent_presenter)
    wrapped = wrap_text(struct[:author] + '___' + struct[:title], 150)
    parts = wrapped.split('___')
    [
      { text: parts[0] },
      { text: parts[1], styles: [:italic] },
      { text: "\n" + wrap_text(struct[:publisher], 150) },
      { text: "\nDownloaded on behalf of #{@request_origin}" }
    ]
  end

  def request_origin
    @request_origin ||= current_institution&.name || request.remote_ip
  end

  def parent_presenter
    @parent_presenter ||= Sighrax.hyrax_presenter(@ebook.parent)
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

  def cache_key
    text = @watermark_formatted_text.to_s + @title.to_s + @chapter_index.to_s
    "pdfwm:#{@ebook.noid}-#{Digest::MD5.hexdigest(text)}-#{cache_key_timestamp}"
  end

  def cache_key_timestamp
    ActiveFedora::SolrService.query("{!terms f=id}#{@ebook.noid}", rows: 1).first['timestamp']
  rescue StandardError => _e
    ''
  end

  instrument_method
  def create_watermark_pdf
    # This is an attempt to get the right size for the bounding box
    size = 10
    text = @watermark_formatted_text.pluck(:text).join('')
    height = (text.lines.count + 1) * size
    width = 0
    text.lines.each do |line|
      width = (width < line.size) ? line.size : width
    end
    width *= (size / 2.0)

    # Prawn won't accept @watermark_formatted_text but will accept the local fmt. I don't know why.
    fmt = @watermark_formatted_text

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
            formatted_text fmt
          end
        end
      end
    end
    pdf.render_file(@stamp_file_path)
  end

  #
  # The methods below have been replaced by an ajax -> job -> web sockets workflow
  # but they still might be used if that workflow fails for some reason
  #
  instrument_method
  def build_and_send_watermarked_pdf
    Rails.cache.fetch(@cache_key, expires_in: 30.days) do
      create_watermark_pdf unless File.exist? @stamp_file_path

      command = "pdftk #{@file_path} stamp #{@stamp_file_path} output #{@stamped_file_path}"

      run_command_with_timeout(command, 120) # Timout in seconds see HELIO-4530, HELIO-4534
      IO.binread(@stamped_file_path)
    end
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
      raise "Unable to execute command \"#{cmd}\"\n#{err}\n#{out}" unless exit_status.success?
    end
  end
end
