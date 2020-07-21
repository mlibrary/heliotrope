# frozen_string_literal: true

class HandleJob < ApplicationJob
  def perform
    # Delete all action delete verified records older than 30 days ago
    HandleDeposit.where("updated_at <= ?", HandleJob.thirty_days_ago).where(action: 'delete', verified: true).delete_all

    # Force create action for all existing models
    model_docs.each do |model_doc|
      record = HandleDeposit.find_or_create_by(noid: model_doc['id'])
      record.touch # rubocop:disable Rails/SkipsModelValidations
      next if /^create$/.match?(record.action)

      record.action = 'create'
      record.verified = false
      record.save
    end

    # Force delete action for all untouched records older than 30 days ago
    HandleDeposit.where("updated_at <= ?", HandleJob.thirty_days_ago).where.not(action: 'delete').each do |record|
      record.action = 'delete'
      record.verified = false
      record.save
    end

    # Create handles for existing models
    HandleDeposit.where(action: 'create', verified: false).each do |record|
      HandleCreateJob.perform_now(record.noid)
    end

    # Delete handles of deleted models
    HandleDeposit.where(action: 'delete', verified: false).each do |record|
      HandleDeleteJob.perform_now(record.noid)
    end

    # Verify creation/deletion of handles
    HandleDeposit.where(verified: false).each do |record|
      HandleVerifyJob.perform_now(record.noid)
    end

    # Return true to simplify unit test a.k.a. it { is_expected.to be true }
    true
  end

  def model_docs
    ActiveFedora::SolrService.query(
      "+(has_model_ssim:Monograph OR has_model_ssim:FileSet)",
      fl: %w[id has_model_ssim],
      rows: 100_000
    ) || []
  end

  # Makes unit test easier to write
  def self.thirty_days_ago
    30.days.ago
  end
end
