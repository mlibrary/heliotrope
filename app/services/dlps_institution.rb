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
      # If the request's entity_id doesn't match any Institutions, return empty array
      return [] if entity_id.blank?

      institutions = Greensub::Institution.where(entity_id: entity_id).to_a
      # HELIO-4961 Security domains
      # If the request comes in without security domains, match on entity_id
      # If the request comes in with security domains
      #   and *no* entity_id matching Fulcrum Institutions have security domains
      #     match on entity_id
      #   if *some or all* entity_id matching Fulcrum Institutions have security domains
      #     match on security domain
      # If we didn't get a match it means we either forgot to add the Institution's security domain,
      # or they are from an Institution that is not in Fulcrum, but shares an entity_id with Institution that is.
      if !Flipflop.use_shib_security_domain_logic?
        institutions
      else
        affiliations = Array(request_attributes[:eduPersonScopedAffiliation])
        shib_security_domains = affiliations.filter_map { |aff| aff.split('@').last.strip if aff.include?('@') }.compact.uniq

        # If the Sihb request comes in without security domains, match on entity_id
        return institutions if shib_security_domains.blank?

        # If the request comes in with security domains
        sec_dom_institutions = institutions.select { |inst| inst.respond_to?(:security_domain) && inst.security_domain.present? }
        # and if *no* entity_id matching Institutions have security domains, fall back to match on entity_id
        return institutions if sec_dom_institutions.blank?

        # If there are any entity_id matching Institutions with security domains, try to match on security_domain
        sec_dom_matches = []
        sec_dom_institutions.each do |inst|
          if inst.security_domain.present? && shib_security_domains.include?(inst.security_domain)
            sec_dom_matches << inst
          end
        end
        return sec_dom_matches if sec_dom_matches.present?

        # If we're here it means:
        # * The request has security domain
        # * There are entity_id matching Institutions that have security domains,
        #   but none of those Institutions matched the shib request's security domain.
        # So either we made a mistake and forgot to add the Institution's security domain to the DB,
        # or the request is from an Institution that is not in Fulcrum, but has an entity_id shared with an Institution that is.
        # see https://mlit.atlassian.net/browse/HELIO-4961?focusedCommentId=368252

        # As long as the entity_id matches, we're going to let them in as an entityID matching Institution.
        # This isn't exactly right, but is consistant with how we've historically used entity_id
        Rails.logger.warn("DlpsInstitution: Shib request from entity_id #{entity_id} with security domain(s) #{shib_security_domains.join(', ')} did not match any Institution security domains. Allowing access based on entity_id match alone.")
        institutions
      end
    end
end
