# frozen_string_literal: true

module Marc
  class Sftp
    attr_reader :conn

    def self.download_marc_ingest_files
      to_download = []
      conn.dir.foreach("/home/fulcrum_ftp/marc_ingest") do |entry|
        if entry.file?
          to_download << entry.name
        end
      end

      files = []
      to_download.each do |file|
        remote = File.join("/home/fulcrum_ftp/marc_ingest", file)
        local = File.join(local_marc_processing_dir, file)
        conn.download!(remote, local)
        files << local
      end

      files
    end

    def self.move_marc_ingest_file_to_product_dir(file, dir)
      file = File.basename(file)
      from = File.join("/home/fulcrum_ftp/marc_ingest", file)
      to = File.join(dir, file)
      begin
        conn.rename!(from, to)
      rescue Net::SFTP::StatusException => e
        MarcLogger.error("Marc::Sftp could not rename!(#{from}, #{to})")
        MarcLogger.error(e)
        raise
      end
    end

    def self.remove_marc_ingest_file(file)
      file = File.basename(file)
      conn.remove!(File.join("/home/fulcrum_ftp/marc_ingest", file))
    end

    def self.local_marc_processing_dir
      path = File.join(Settings.scratch_space_path, "marc_processing")
      FileUtils.mkdir_p(path) unless Dir.exist? path
      path.to_s
    end

    def self.conn
      config = yaml_config
      @conn ||= if config.present?
                  sftp = config['fulcrum_sftp_credentials']
                  Net::SFTP.start(sftp["sftp"], sftp["user"], password: sftp["password"])
                else
                  MarcLogger.error("No ftp.fulcrum.org credentials present!")
                  nil
                end
    rescue Net::SFTP::StatusException, Net::SSH::Disconnect => e
      MarcLogger.error(e)
      MarcLogger.error(e.backtrace.join("\n"))
    end

    def self.yaml_config
      config = Rails.root.join('config', 'fulcrum_sftp.yml')
      yaml = YAML.safe_load(File.read(config)) if File.exist? config
      yaml || nil
    end
  end
end
