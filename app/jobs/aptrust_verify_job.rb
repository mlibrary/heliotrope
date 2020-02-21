# frozen_string_literal: true

class AptrustVerifyJob < ApplicationJob
  def perform(monograph_id)
    monograph = Sighrax.from_noid(monograph_id)
    return false unless monograph.is_a?(Sighrax::Monograph)

    record = AptrustDeposit.find_by(noid: monograph_id)
    return false unless record

    return true if record.verified

    verify(record)
  end

  def verify(record)
    case Aptrust::Service.new.ingest_status(record.identifier)
    when /success/i
      record.verified = true
      record.save
      true
    when /failed/i, /not_found/i
      record.delete
      false
    else
      false
    end
  rescue StandardError => e
    Rails.logger.error "Aptrust::Service.new.ingest_status(#{record.identifier}) #{e}"
    false
  end
end
