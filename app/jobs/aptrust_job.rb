# frozen_string_literal: true

class AptrustJob < ApplicationJob
  def perform
    rvalue = 0
    Rails.logger.debug "Aptrust Job Deposit Monographs ..."
    monograph_docs.each do |monograph_doc|
      next if deposit_up_to_date?(monograph_doc)
      AptrustDepositJob.perform_now(monograph_doc['id'])
      rvalue += 1
    end
    Rails.logger.debug "Aptrust Job Deposited #{rvalue} Monographs"
    rvalue
  end

  def monograph_docs
    ActiveFedora::SolrService.query(
      "+has_model_ssim:Monograph AND +visibility_ssi:open AND -suppressed_bsi:true",
      fl: %w[id date_modified_dtsi has_model_ssim suppressed_bsi visibility_ssi],
      rows: 100_000
    ) || []
  end

  def file_set_docs(monograph_doc)
    ActiveFedora::SolrService.query(
      "+has_model_ssim:FileSet AND +monograph_id_ssim:#{monograph_doc['id']}",
      fl: %w[id date_modified_dtsi has_model_ssim monograph_id_ssim],
      rows: 100_000
    ) || []
  end

  def deposit_up_to_date?(monograph_doc)
    record = AptrustDeposit.find_by(noid: monograph_doc['id'])
    return false unless record
    date_deposited = Time.parse(record.created_at.to_s).utc
    return false if Time.parse(monograph_doc['date_modified_dtsi'].to_s).utc > date_deposited
    file_set_docs(monograph_doc).each do |file_set_doc|
      return false if Time.parse(file_set_doc['date_modified_dtsi'].to_s).utc > date_deposited
    end
    true
  end
end
