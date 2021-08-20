# frozen_string_literal: true

module Greensub
  module Licensee # rubocop:disable Metrics/ModuleLength
    def find_product_license(product, affiliation: 'member')
      case self
      when Individual
        find_individual_product_license(product)
      when Institution
        find_institution_product_license(product, affiliation: affiliation)
      else
        raise StandardError "Unknown Licensee Class #{self.class}"
      end
    end

    def find_individual_product_license(product)
      pls = licenses.where(product: product)
      case pls.count
      when 0
        nil
      when 1
        pls.first
      else
        raise StandardError "Individual #{licensee.identifier} has multiple licenses to product #{product.identifier}"
      end
    end

    def find_institution_product_license(product, affiliation: 'member')
      pls = licenses.where(product: product)
      plas = LicenseAffiliation.where(license: pls, affiliation: affiliation)
      case plas.count
      when 0
        nil
      when 1
        plas.first.license
      else
        raise StandardError "Institution #{licensee.identifier} has multiple licenses with affiliation #{affiliation} to product #{product.identifier}"
      end
    end

    def create_product_license(product, affiliation: 'member', type: FullLicense.to_s)
      case self
      when Individual
        create_individual_product_license(product, type: type)
      when Institution
        create_institution_product_license(product, affiliation: affiliation, type: type)
      else
        raise StandardError "Unknown Licensee Class #{self.class}"
      end
    end

    def create_individual_product_license(product, type: FullLicense.to_s)
      pls = licenses.where(product: product)
      case pls.count
      when 0
        pl = License.create!(licensee: self, type: type, product: product)
        Authority.grant!(self, pl, product)
        pl
      when 1
        pl = pls.first
        pl.type = type
        pl.save!
        licenses.find(pl.id)
      else
        raise StandardError "Individual #{licensee.identifier} has multiple licenses to product #{product.identifier}"
      end
    end

    def create_institution_product_license(product, affiliation: 'member', type: FullLicense.to_s) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      pls = licenses.where(product: product)
      plas = LicenseAffiliation.where(license: pls, affiliation: affiliation)
      case plas.count
      when 0
        pl = pls.find_by(type: type)
        if pl.present?
          LicenseAffiliation.create!(license: pl, affiliation: affiliation)
          pl
        else
          pl = License.create!(licensee: self, type: type, product: product)
          LicenseAffiliation.create!(license: pl, affiliation: affiliation)
          Authority.grant!(self, pl, product)
          pl
        end
      when 1
        pla = plas.first
        pl = pla.license
        if pl.type == type
          pl
        else
          pl_type = pls.find_by(type: type)
          if pl_type.blank?
            if pl.affiliations.count == 1
              pl.type = type
              pl.save!
              licenses.find(pl.id)
            else
              pl = License.create!(licensee: self, type: type, product: product)
              pla.license = pl
              pla.save!
              Authority.grant!(self, pl, product)
              pl
            end
          else
            pla.license = pl_type
            pla.save!
            pl.reload
            if pl.affiliations.blank?
              Authority.revoke!(self, pl, product)
              pl.destroy!
            end
            pl_type
          end
        end
      else
        raise StandardError "Institution #{licensee.identifier} has multiple licenses affiliation #{affiliation} to product #{product.identifier}"
      end
    end

    def delete_product_license(product, affiliation: 'member')
      case self
      when Individual
        delete_individual_product_license(product)
      when Institution
        delete_institution_product_license(product, affiliation: affiliation)
      else
        raise StandardError "Unknown Licensee Class #{self.class}"
      end
    end

    def delete_individual_product_license(product)
      pls = licenses.where(product: product)
      case pls.count
      when 0
        nil
      when 1
        pl = pls.first
        Authority.revoke!(self, pl, product)
        pl.destroy!
      else
        raise StandardError "Individual #{licensee.identifier} has multiple licenses to product #{product.identifier}"
      end
    end

    def delete_institution_product_license(product, affiliation: 'member')
      pls = licenses.where(product: product)
      plas = LicenseAffiliation.where(license: pls, affiliation: affiliation)
      case plas.count
      when 0
        nil
      when 1
        pla = plas.first
        pl = pla.license
        pla.destroy!
        if pl.affiliations.blank?
          Authority.revoke!(self, pl, product)
          pl.destroy!
        else
          nil
        end
      else
        raise StandardError "Institution #{licensee.identifier} has multiple licenses affiliation #{affiliation} to product #{product.identifier}"
      end
    end

    def products?
      products.present?
    end

    def products
      Product.where(id: licenses.pluck(:product_id)).uniq
    end

    def licenses?
      licenses.present?
    end

    def licenses
      License.where(licensee_type: self.class.to_s, licensee_id: self.id)
    end

    def grants?
      grants.present?
    end

    def grants
      Checkpoint::DB::Grant.where(agent_type: agent_type.to_s, agent_id: agent_id.to_s)
    end
  end
end
