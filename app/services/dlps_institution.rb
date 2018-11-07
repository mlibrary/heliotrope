# frozen_string_literal: true

class DlpsInstitution
  def find(request_attributes)
    (ip_based_institutions(request_attributes) + shib_institutions(request_attributes)).uniq
  end

  private

    def ip_based_institutions(request_attributes)
      ids = request_attributes[:dlpsInstitutionId]
      return [] if ids.blank?
      Institution.where(identifier: ids).to_a
    end

    def shib_institutions(request_attributes)
      entity_id = request_attributes[:identity_provider]
      return [] if entity_id.blank?
      Institution.where(entity_id: entity_id).to_a
    end
end
