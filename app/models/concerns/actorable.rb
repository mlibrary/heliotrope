# frozen_string_literal: true

module Actorable
  extend ActiveSupport::Concern
  include Skylight::Helpers

  instrument_method
  def individual
    if Incognito.sudo_actor?(self)
      Incognito.sudo_actor_individual(self)
    else
      Greensub::Individual.find_by(email: email) if email.present?
    end
  end

  instrument_method
  def institutions
    if Incognito.sudo_actor?(self)
      [Incognito.sudo_actor_institution(self)].compact
    else
      Services.dlps_institution.find(request_attributes)
    end
  end

  instrument_method
  def affiliations(institution)
    if Incognito.sudo_actor?(self)
      [Incognito.sudo_actor_institution_affiliation(self)].compact.select { |ia| ia.institution_id == institution.id }
    else
      Services.dlps_institution_affiliation.find(request_attributes).select { |ia| ia.institution_id == institution.id }
    end
  end

  instrument_method
  def products
    Greensub::Product.where(id: licenses.pluck(:product_id)).uniq
  end

  instrument_method
  def licenses # rubocop:disable Metrics/CyclomaticComplexity
    licenses = individual&.licenses.to_a || []
    institutions.each do |institution|
      institution.licenses.each do |license|
        licenses << license if (license.license_affiliations.map(&:affiliation) & affiliations(institution).map(&:affiliation)).any?
      end
    end
    licenses.uniq
  end
end
