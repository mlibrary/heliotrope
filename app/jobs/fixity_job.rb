# frozen_string_literal: true

# monkeypatch AF connection with a longer timout when running fixity checks, HELIO-4011
module ActiveFedora
  class FixityService
    def fixity_response_from_fedora
      uri = target + "/fcr:fixity"
      # ActiveFedora.fedora.connection.get(encoded_url(uri))
      af = ActiveFedora::Fedora.register({ request: { timeout: 180, open_timeout: 180 } })
      Rails.logger.info("FIXITY AF CONNECTION MONKEYPATCH: timeout:#{af.connection.http.options.timeout}, open_timeout:#{af.connection.http.options.open_timeout}")
      af.connection.get(encoded_url(uri))
    end
  end
end

class FixityJob < ApplicationJob
  queue_as :fixity

  def perform # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity:
    ActiveRecord::Base.clear_active_connections! # https://github.com/resque/resque#rails-4x

    failures = []

    file_set_ids = ActiveFedora::SolrService.query("+has_model_ssim:FileSet",
                                                  fl: ['id'],
                                                  sort: 'date_modified_dtsi desc',
                                                  rows: FileSet.all.count).map(&:id)

    file_set_ids.each do |file_set_id|
      next if ChecksumAuditLog.where(file_set_id: file_set_id).where("updated_at > ?", 30.days.ago).where(passed: true).present?

      Rails.logger.tagged(SecureRandom.uuid) do
        response = run_fixity_check(file_set_id)
        Rails.logger.info("FIXITY RESPONSE: #{response}")

        Rails.logger.info("FIXITY ERROR PRESENT? #{response[:error].present?}")
        # By error here we mean a timout or something, not a checksum failure
        next if response[:error].present?

        # If we got a checksum failure and we've had at least 2 before that, without a success, then send an email.
        # The problem is the MASSIVE amounts of "fake" failures that constantly happen where one time the checksum is
        # bad but the next day it's good. So I guess this is what we have to do to try to avoid fake reporting those.
        # Essentially: a file has to have a bad checksum multiple times over multiple days. It needs to fail like 12 times
        # in a row in order to actually have an email sent.
        # It's madness, but we can't have false failures.
        if response[:passed] == false
          ChecksumAuditLog.create!(passed: response[:passed], file_set_id: response[:file_set_id], checked_uri: response[:checked_uri], file_id: response[:file_id], expected_result: response[:expected_result])
          if ChecksumAuditLog.where(file_set_id: response[:file_set_id], passed: false).count >= 4
            failures << response
          end
        else
          create_or_replace(response)
        end
      end
    end

    FixityMailer.send_failures(failures).deliver_now if failures.present?
  end

  def create_or_replace(response)
    # We only keep a single row for a file_set/file that has passed: true
    return unless response[:passed] == true
    ChecksumAuditLog.where(file_set_id: response[:file_set_id]).destroy_all
    ChecksumAuditLog.create!(passed: response[:passed], file_set_id: response[:file_set_id], checked_uri: response[:checked_uri], file_id: response[:file_id], expected_result: response[:expected_result])
  end


  def run_fixity_check(file_set_id, try = 1) # rubocop:disable Metrics/CyclomaticComplexity
    # Only run fixity checking on the original file's current version.
    # No checks on extra Apache Tika OCR files from pdfs created by Characterization
    # No checks on old original_file versions

    # Fixity checks fail sometimes, either a HTTP timeout or a BAD_CHECKSUM
    # But then if you run it again, it's fine.
    # So we'll bake that in. Failing checks get to be tried multiple times before we accept the failure.
    try_limit = 4
    Rails.logger.info("FIXITY CHECK for file_set: #{file_set_id}, try: #{try}")
    Rails.logger.info("FIXITY Sleep 1")
    sleep(1) # This actually seems to help fixity pass by giving fedora a "rest" between checks

    response = {}
    response[:file_set_id] = file_set_id

    file_set = FileSet.find file_set_id
    if file_set.original_file.nil?
      response[:error] = "no_original_file_present"
      return response
    end

    unless file_set.original_file.has_versions?
      response[:error] = "no_versions_present"
      return response
    end

    uri = file_set.original_file.versions.all.max_by(&:created).uri.to_s

    service = ActiveFedora::FixityService.new(uri)
    begin
      fixity_ok = service.check
      expected_result = service.expected_message_digest
    rescue Ldp::NotFound
      response[:error] = "fixity_ldp_not_found"
    rescue Faraday::TimeoutError
      Rails.logger.info("FIXITY TIMOUT FOR #{file_set_id}")
      response[:error] = "fixity_timeout"
      run_fixity_check(file_set_id, try + 1) unless try > try_limit
    end

    if fixity_ok == false
      Rails.logger.info("FIXITY CHECK FAILED FOR #{file_set_id}")
      run_fixity_check(file_set_id, try + 1) unless try > try_limit
    end

    response[:file_id] = file_set.original_file.id
    response[:checked_uri] = uri
    response[:passed] = fixity_ok
    response[:expected_result] = expected_result

    response
  end
end
