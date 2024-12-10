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

    def download_retry_files
      to_download = []
      conn.dir.foreach("/home/fulcrum_ftp/marc_ingest/retry") do |entry|
        if entry.file?
          to_download << entry.name
        end
      end

      files = []
      to_download.each do |file|
        remote = File.join("/home/fulcrum_ftp/marc_ingest/retry", file)
        local = File.join(local_marc_processing_dir, file)
        conn.download!(remote, local)
        files << local
      end

      files

    rescue StandardError => e
      MarcLogger.error("Marc::Sftp download_retry_files failed with #{e}")
      []
    end

    def upload_local_marc_file_to_remote_product_dir(local_file, product_dir)
      remote_file = File.join(product_dir, File.basename(local_file))
      conn.upload!(local_file, remote_file)
    rescue Net::SFTP::StatusException, StandardError => e
      MarcLogger.error("Marc::Sftp could not upload!(#{local_file}, #{remote_file}): #{e}")
    end

    def remove_marc_ingest_file(file)
      remote_file = File.join("/home/fulcrum_ftp/marc_ingest", File.basename(file))
      conn.remove!(remote_file)
      MarcLogger.info("Marc::Sftp removed #{remote_file}")
    rescue Net::SFTP::StatusException => e
      MarcLogger.error("Marc::Sftp could not remove!(#{remote_file}), #{e}")
    end

    def upload_local_marc_file_to_remote_failures(local_file)
      remote_file = File.join("/home/fulcrum_ftp/marc_ingest/failures", File.basename(local_file))
      conn.upload!(local_file, remote_file)
    rescue Net::SFTP::StatusException, StandardError => e
      MarcLogger.error("Marc::Sftp could not rename!(#{local_file}, #{remote_file}): #{e}")
    end

    # If we find a record that is not in fulcrum, we put it in ~/marc_ingest/retry to be retried another day
    def upload_unknown_local_marc_file_to_retry(local_file)
      remote_file = File.join("/home/fulcrum_ftp/marc_ingest/retry", File.basename(local_file))
      conn.upload!(local_file, remote_file)
    rescue Net::SFTP::StatusException, StandardError => e
      MarcLogger.error("Marc::Sftp could not upload!(#{local_file}, #{remote_file}): #{e}")
    end

    # After we find a retry file's monograph and put it in the correct product dir, remove it from the retry dir
    def remove_remote_retry_file(original_file_name)
      remote_file = File.join("/home/fulcrum_ftp/marc_ingest/retry", File.basename(original_file_name))
      conn.remove!(remote_file)
    rescue Net::SFTP::StatusException, StandardError => e
      MarcLogger.error("Marc::Sftp could not remove!(#{remote_file}): #{e}")
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
