# frozen_string_literal: true

module Greensub
  module Licensee
    def product_license?(product)
      product_license(product).present?
    end

    def product_license(product)
      pl = licenses.where(product: product)
      pl.first
    end

    def update_product_license(product, license_type: "Greensub::FullLicense")
      pl = product_license(product)
      if pl.present?
        pl.type = license_type
        pl.save
      else
        pl = License.create(licensee: self, type: license_type, product: product)
        Authority.grant!(self, pl, product)
      end
    end

    def delete_product_license(product)
      pl = product_license(product)
      return nil if pl.blank?

      Authority.revoke!(self, pl, product)
      pl.destroy
    end

    def products?
      products.present?
    end

    def products
      Product.where(id: licenses.pluck(:product_id))
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
