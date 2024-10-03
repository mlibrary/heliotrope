# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

class MarcIngestJob < ApplicationJob
  def perform
    report = []

    MarcLogger.info("Beginning MarcIngestJob...")

    files = Marc::Sftp.download_marc_ingest_files

    MarcLogger.info("No new marc files found in /marc_ingest") && return if files.blank?
    MarcLogger.info("#{files.count} files found in /marc_ingest")

    files.each do |file|
      validator = Marc::Validator.new(file)

      if validator.valid?
        product_dir = Marc::DirectoryMapper.group_key_cataloging[validator.group_key]
        if product_dir.blank?
          error = "ERROR\tMarc::DirectoryMapper is missing a group_key/cataloging path for '#{validator.group_key}' with file '#{file}'!"
          MarcLogger.error(error)
          report << error
          FileUtils.rm file
          next
        end

        Marc::Sftp.move_marc_ingest_file_to_product_dir(validator.file, product_dir)

        report << "SUCCESS\t#{validator.group_key} #{validator.noid} #{File.basename(validator.file)} moved to #{product_dir}"

        # The file has been moved out of the remote ~/marc_ingest, just delete the local copy
        FileUtils.rm file
      else
        FileUtils.rm file
        report << validator.error
      end
    end

    MarcLogger.info("MarcIngestJob finished")
    report.each do |r|
      MarcLogger.info(r)
    end

    MarcIngestMailer.send_mail(report)
  end
end
