# frozen_string_literal: true

# monkeypatch AF connection with a longer timout when running fixity checks, HELIO-4011
module ActiveFedora
  class FixityService
    def fixity_response_from_fedora
      uri = target + "/fcr:fixity"
      # ActiveFedora.fedora.connection.get(encoded_url(uri))
      af = ActiveFedora::Fedora.register({ request: { timeout: 120, open_timeout: 120 } })
      Rails.logger.info("FIXITY AF CONNECTION MONKEYPATCH: timeout:#{af.connection.http.options.timeout}, open_timeout:#{af.connection.http.options.open_timeout}")
      af.connection.get(encoded_url(uri))
    end
  end
end

class FixityJob < ApplicationJob
  queue_as :fixity

  def perform
    ActiveRecord::Base.clear_active_connections! # https://github.com/resque/resque#rails-4x

    failures = []

    file_set_ids = ActiveFedora::SolrService.query("+has_model_ssim:FileSet",
                                                  fl: ['id'],
                                                  sort: 'date_modified_dtsi desc',
                                                  rows: FileSet.all.count).map(&:id)

    # Temporarily set a limit on the number of new file_sets to be checked so we can
    # stagger the initial fixity checking over a number of days instead of doing them all
    # on one day. After all files have the initial check, remove the limit

    limit = 2000 # todo: remove
    current = 0 # todo: remove
    file_set_ids.each do |file_set_id|
      next if ChecksumAuditLog.where(file_set_id: file_set_id).where("updated_at > ?", 30.days.ago).present? # todo: remove
      next if current >= limit # todo: remove

      response = run_fixity_check(file_set_id)
      Rails.logger.info("FIXITY RESPONSE-----------------------------------------------------------")
      Rails.logger.info(response)

      Rails.logger.info("FIXITY ERROR PRESENT? #{response[:error].present?}")
      next if response[:error].present?
      failures << response if response[:passed] == false

      ChecksumAuditLog.create_and_prune!(passed: response[:passed], file_set_id: response[:file_set_id], checked_uri: response[:uri], file_id: response[:file_id], expected_result: response[:expected_result])

      current += 1 # todo: remove

      Rails.logger.info("FIXITY Sleep 1")
      sleep(1)
    end

    FixityMailer.send_failures(failures).deliver_now if failures.present?
  end

  def run_fixity_check(file_set_id, try = 0) # rubocop:disable Metrics/CyclomaticComplexity
    # Only run fixity checking on the original file's current version.
    # No checks on extra Apache Tika OCR files from pdfs created by Characterization
    # No checks on old original_file versions

    # Fixity checks fail sometimes, either a HTTP timeout or a BAD_CHECKSUM
    # But then if you run it again, it's fine.
    # So we'll bake that in. Failing check get to be tried multiple times before we accept the failure.
    try_limit = 3
    Rails.logger.info("FIXITY CHECK for file_set: #{file_set_id}, try: #{try}")

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
      response[:error] = "FIXITY Ldp::NotFound FOR #{file_set_id}"
    rescue Faraday::TimeoutError
      Rails.logger.info("FIXITY TIMOUT FOR #{file_set_id}")
      run_fixity_check(file_set_id, try + 1) unless try >= try_limit
    end

    if fixity_ok == false
      Rails.logger.info("FIXITY CHECK FAILED FOR #{file_set_id}")
      run_fixity_check(file_set_id, try + 1) unless try >= try_limit
    end

    response[:file_id] = file_set.original_file.id
    response[:uri] = uri
    response[:passed] = fixity_ok
    response[:expected_result] = expected_result
    response[:tries] = try

    response
  end
end
