# frozen_string_literal: true

class DlpsInstitution
  include Skylight::Helpers

  instrument_method
  def find(request_attributes)
    retries ||= 0
    (ip_based_institutions(request_attributes) + shib_institutions(request_attributes)).uniq
  rescue  StandardError => e
    Rails.logger.error(%Q|DlpsInstitution RETRY #{retries}: #{e} #{e.backtrace.join("\n")}|)
    retries += 1
    retry if retries < 3
  end

  private

    instrument_method
    def ip_based_institutions(request_attributes)
      ids = request_attributes[:dlpsInstitutionId]
      return [] if ids.blank?

      Greensub::Institution.where(id: Greensub::InstitutionAffiliation.where(dlps_institution_id: ids).pluck(:institution_id).uniq).to_a
    end

    instrument_method
    def shib_institutions(request_attributes)
      entity_id = request_attributes[:identity_provider]
      return [] if entity_id.blank?

      Greensub::Institution.where(entity_id: entity_id).to_a
    end
end
