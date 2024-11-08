# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

class MarcIngestJob < ApplicationJob
  def perform
    report = []
    sftp = Marc::Sftp.new
    lfh = Marc::LocalFileHandler.new

    MarcLogger.info("Beginning MarcIngestJob...")

    files = sftp.download_marc_ingest_files

    MarcLogger.info("#{files.count} files found in /marc_ingest")

    marc_files = lfh.convert_to_individual_marc_files(files)

    MarcLogger.info("No MARC records found in files: #{files.join(',')}") if marc_files.empty?

    marc_files.each do |file|
      validator = Marc::Validator.new(file)

      if validator.valid?
        product_dir = Marc::DirectoryMapper.group_key_cataloging[validator.group_key]
        if product_dir.blank?
          # This record could be valid, we just don't have a group_key for it yet.
          # So don't move it to the failures directory
          error = "ERROR\tMarc::DirectoryMapper is missing a group_key for '#{file}'!"
          MarcLogger.error(error)
          report << error
          next
        end

        # Rename the file to something more descriptive
        renamed_file = lfh.rename_file_with_noid(validator)
        sftp.upload_local_marc_file_to_remote_product_dir(renamed_file, product_dir)
        report << "SUCCESS\t#{validator.group_key} #{validator.noid} #{File.basename(renamed_file)} moved to #{product_dir}"
      else
        sftp.upload_local_marc_file_to_remote_failures(validator.file)
        report << validator.error
      end
    end

    # Done. Delete all the local directories
    lfh.clean_up_processing_dir
    # Remove the original Alma file(s) that were in the remote ~/marc_ingest since they've been untarred, split and renamed
    files.each do |file|
      sftp.remove_marc_ingest_file(file)
    end

    MarcLogger.info("MarcIngestJob finished")
    report.each do |r|
      MarcLogger.info(r)
    end

    MarcIngestMailer.send_mail(report).deliver_now if report.count > 0
  end
end
