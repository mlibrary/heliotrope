# frozen_string_literal: true

class DlpsInstitution
  include Skylight::Helpers

  instrument_method
  def find(request_attributes)
    retries ||= 0
    (ip_based_institutions(request_attributes) + shib_institutions(request_attributes).uniq).uniq
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

      all_shib = Greensub::Institution.where(entity_id: entity_id).to_a
      affiliations = Array(request_attributes[:eduPersonScopedAffiliation])
      security_domains = affiliations.filter_map { |aff| aff.split('@').last.strip if aff.include?('@') }.compact.uniq

      # Per HELIO-4961 if there's a matching security_domain(s), use that and throw any matching entity_id instititons away
      # If there at no security_domains, return entity_id matched institutions
      return all_shib if security_domains.empty?

      # If there are matching security_domains, return those
      sec_dom_matches = []
      all_shib.each do |inst|
        if inst.respond_to?(:security_domain) && inst.security_domain.present? && security_domains.include?(inst.security_domain)
          sec_dom_matches << inst
        end
      end
      # If there are some matching security_domains, return those, otherwise return nothing
      sec_dom_matches || []
    end
end
