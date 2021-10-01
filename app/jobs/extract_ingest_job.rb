# frozen_string_literal: true

class ExtractIngestJob < ApplicationJob
  def perform(token, base, source, target) # rubocop:disable Metrics/CyclomaticComplexity
    return unless ValidationService.valid_noid?(source)
    press = Press.where(subdomain: target)
    return if press.blank?
    turnsole_service = Turnsole::Service.new(token, base)

    Rails.logger.debug "Monograph Extract"
    extract_file = File.join(extract_path, "#{source}.zip")
    FileUtils.rm_rf(extract_file) if File.exist?(extract_file)
    File.open(extract_file, 'wb') { |fp| fp.write(turnsole_service.monograph_extract(source)) }
    extract_dir = File.join(extract_path, source)
    FileUtils.rm_rf(extract_dir) if Dir.exist?(extract_dir)
    FileUtils.mkdir(extract_dir)
    begin
      Zip::File.open(extract_file) do |zipfile|
        zipfile.each do |entry|
          entry.extract(File.join(extract_dir, entry.name))
        end
      end
    rescue StandardError => e
      Rails.logger.debug { "ERROR: #{e}" }
      return
    end
    FileUtils.rm_rf(extract_file)
    return unless Dir.exist?(extract_dir)

    Rails.logger.debug "Monograph Ingest"
    importer = Import::Importer.new(root_dir: extract_dir, press: target)
    importer.run
  end

  private

    def manifest_path
      return @manifest_path if @manifest_path.present?
      @manifest_path = Rails.root.join('tmp', 'import', 'manifest')
      FileUtils.mkdir_p(@manifest_path) unless Dir.exist?(@manifest_path)
      @manifest_path
    end

    def extract_path
      return @extract_path if @extract_path.present?
      @extract_path = Rails.root.join('tmp', 'import', 'extract')
      FileUtils.mkdir_p(@extract_path) unless Dir.exist?(@extract_path)
      @extract_path
    end
end
