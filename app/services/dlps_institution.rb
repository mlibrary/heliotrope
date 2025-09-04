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

      institutions = Greensub::Institution.where(entity_id: entity_id).to_a
      if !Flipflop.use_shib_security_domain_logic?
        Rails.logger.info("DlpsInstitution: returning institutions without security_domain logic")
        Rails.logger.info("DlpsInstitution: institutions: #{institutions.map(&:name).join(', ')}")
        institutions
      else
        affiliations = Array(request_attributes[:eduPersonScopedAffiliation])
        shib_security_domains = affiliations.filter_map { |aff| aff.split('@').last.strip if aff.include?('@') }.compact.uniq

        # HELIO-4961
        # If there are multiple Institutions that match the entity_id,
        # and *none* of those institutions have a security_domain
        # or there are no security_domains in eduPersonScopedAffiliation
        # then just return the entity_id matches
        inst_security_domains = institutions.select { |inst| inst.respond_to?(:security_domain) && inst.security_domain.present? }
        Rails.logger.info("DlpsInstitution: institution security_domains: #{inst_security_domains.map(&:security_domain).join(', ')}")
        Rails.logger.info("DlpsInstitution: shib security_domains: #{shib_security_domains.join(', ')}")
        return institutions if inst_security_domains.blank? || shib_security_domains.blank?

        # If there are matching security_domains then only return institutions that match
        # the security_domain values from eduPersonScopedAffiliation.
        # If there are no security_domain matches then return an empty array
        sec_dom_matches = []
        inst_security_domains.each do |inst|
          if inst.security_domain.present? && shib_security_domains.include?(inst.security_domain)
            sec_dom_matches << inst
          end
        end

        Rails.logger.info("DlpsInstitution: sec_dom_matches institutions: #{sec_dom_matches.map(&:name).join(', ')}")
        sec_dom_matches || []
      end
    end
end
