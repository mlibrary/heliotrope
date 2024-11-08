# frozen_string_literal: true

module Marc
  class Sftp
    def initialize
      @processing_dir = File.join(Settings.scratch_space_path, "marc_processing")
      FileUtils.mkdir_p(@processing_dir) unless Dir.exist? @processing_dir
      conn
    end

    def download_marc_ingest_files
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

    rescue StandardError => e
      MarcLogger.error("Marc::Sftp download_marc_ingest_files failed with #{e}")
      []
    end

    def upload_local_marc_file_to_remote_product_dir(local_file, product_dir)
      conn.upload!(local_file, product_dir)
    rescue Net::SFTP::StatusException => e
      MarcLogger.error("Marc::Sftp could not upload!(#{from}, #{to})")
      MarcLogger.error(e)
    end


    def remove_marc_ingest_file(file)
      file = File.basename(file)
      conn.remove!(File.join("/home/fulcrum_ftp/marc_ingest", file))
      MarcLogger.info("Marc::Sftp removed #{file}")
    rescue Net::SFTP::StatusException => e
      MarcLogger.error("Marc::Sftp could not remove!(#{file}), #{e}")
    end

    def upload_local_marc_file_to_remote_failures(local_file)
      remote_failure_file = File.join("/home/fulcrum_ftp/marc_ingest/failures", "#{File.basename(local_file)}")
      conn.upload!(local_file, remote_failure_file)
    rescue Net::SFTP::StatusException => e
      MarcLogger.error("Marc::Sftp could not rename!(#{from}, #{to})")
      MarcLogger.error(e)
    end

    def local_marc_processing_dir
      path = File.join(Settings.scratch_space_path, "marc_processing")
      FileUtils.mkdir_p(path) unless Dir.exist? path
      path.to_s
    end

    def conn
      config = yaml_config
      @conn ||= if config.present?
                  sftp = config['fulcrum_sftp_credentials']
                  Net::SFTP.start(sftp["sftp"], sftp["user"], password: sftp["password"])
                else
                  MarcLogger.error("No ftp.fulcrum.org credentials present!")
                  nil
                end
    rescue Net::SFTP::StatusException, Net::SSH::Disconnect, StandardError => e
      MarcLogger.error(e)
    end

    def yaml_config
      config = Rails.root.join('config', 'fulcrum_sftp.yml')
      yaml = YAML.safe_load(File.read(config)) if File.exist? config
      yaml || nil
    end
  end
end
