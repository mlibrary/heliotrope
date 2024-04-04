# frozen_string_literal: true

class DlpsInstitutionAffiliation
  include Skylight::Helpers

  instrument_method
  def find(request_attributes)
    retries ||= 0
    (ip_based_institution_affiliations(request_attributes) + shib_institution_affiliations(request_attributes)).uniq
  rescue  StandardError => e
    Rails.logger.error(%Q|DlpsInstitutionAffiliation RETRY #{retries}: #{e} #{e.backtrace.join("\n")}|)
    retries += 1
    retry if retries < 3
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
