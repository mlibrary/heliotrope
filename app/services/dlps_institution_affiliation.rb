# frozen_string_literal: true

class DlpsInstitutionAffiliation
  include Skylight::Helpers

  MAX_ATTEMPTS = 3
  RETRY_DELAY = 0.1

  instrument_method
  def find(request_attributes)
    attempts = 0
    begin
      attempts += 1
      (ip_based_institution_affiliations(request_attributes) + shib_institution_affiliations(request_attributes)).uniq
    rescue StandardError => e
      Rails.logger.error(%Q|DlpsInstitutionAffiliation attempt #{attempts} of #{MAX_ATTEMPTS} failed: #{e} #{e.backtrace.join("\n")}|)
      # Falling out of the rescue used to return nil, which downstream callers
      # such as Actorable#licenses immediately blew up on. Raise the real error
      # instead so the cause is visible.
      raise if attempts >= MAX_ATTEMPTS

      sleep(RETRY_DELAY * attempts)
      retry
    end
  end

  private

    instrument_method
    def ip_based_institution_affiliations(request_attributes)
      ids = request_attributes[:dlpsInstitutionId]
      return [] if ids.blank?

      Greensub::InstitutionAffiliation.where(dlps_institution_id: ids).to_a
    end

    instrument_method
    def shib_institution_affiliations(request_attributes)
      entity_id = request_attributes[:identity_provider]
      return [] if entity_id.blank?

      ids = Greensub::Institution.where(entity_id: entity_id).pluck(:id).to_a
      affiliations = request_attributes[:eduPersonScopedAffiliation]&.map { |scoped| scoped.strip[0, scoped.strip.index('@')] } || ['member']

      Greensub::InstitutionAffiliation.where(institution_id: ids, affiliation: affiliations).to_a
    end
end
