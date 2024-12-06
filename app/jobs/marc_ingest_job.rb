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
      validator = Marc::Validator.new(file, false)

      if validator.valid?
        product_dir = Marc::DirectoryMapper.group_key_cataloging[validator.group_key]
        if product_dir.blank?
          # This record could be valid, we either don't have a group_key for it yet, or the book itself is not yet in fulcrum.
          # Move it into ~/marc_ingest/retry to be retried again
          sftp.upload_unknown_local_marc_file_to_retry(validator.file)
          report << "MISSING\t'#{file}' with noid:'#{validator.noid}' and group_key:'#{validator.group_key}' is ignored"
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

    # Now get all the single record marc files in ~/marc_ingest/retry and try to match them to Fulcrum monographs again
    retry_files = sftp.download_retry_files

    retry_files.each do |file|
      validator = Marc::Validator.new(file, false)

      # These are already valid, but we use the validator to get the noid/group_key
      if validator.valid?
        product_dir = Marc::DirectoryMapper.group_key_cataloging[validator.group_key]
        if product_dir.blank?
          if validator.group_key == "unknown_group_key"
            report << "RETRIED FAILURE\t'#{file}' with noid:'#{validator.noid}' and group_key:'#{validator.group_key}' still doesn't match a Fulcrum monograph"
          else
            report << "RETRIED FAILURE\t'#{file}' with noid:'#{validator.noid}' is in Fulcrum but is missing a group_key ('#{validator.group_key}'). Make sure the correct group_key is in Marc::DirectoryMapper."
          end
        else
          renamed_file = lfh.rename_file_with_noid(validator)
          sftp.upload_local_marc_file_to_remote_product_dir(renamed_file, product_dir)
          report << "RETRIED SUCCESS\t#{validator.group_key} #{validator.noid} #{File.basename(renamed_file)} moved to #{product_dir}"
          sftp.remove_remote_retry_file(validator.file)
        end
      else
        report << "ERROR! Retry file #{file} is invalid and can not be processed! #{validator.error}"
      end
    end

    report.each do |r|
      MarcLogger.info(r)
    end

    # Done. Delete all the local directories
    lfh.clean_up_processing_dir
    # Remove the original Alma file(s) that were in the remote ~/marc_ingest since they've been untarred, split and renamed
    files.each do |file|
      sftp.remove_marc_ingest_file(file)
    end

    MarcLogger.info("MarcIngestJob finished")

    MarcIngestMailer.send_mail(report).deliver_now if report.count > 0
  end
end
