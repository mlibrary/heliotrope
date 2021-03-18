# frozen_string_literal: true

module Greensub
  module Licensee
    def product_license?(product)
      product_license(product).present?
    end

    def product_license(product)
      pl = License.where(id: grants.where(credential_type: 'License', resource_type: 'Product', resource_id: product.id).map(&:credential_id))
      pl.first
    end

    def update_product_license(product, license_type: "Greensub::FullLicense")
      pl = product_license(product)
      if pl.present?
        pl.type = license_type
        pl.save
      else
        pl = License.create(type: license_type)
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
      Product.where(id: grants.where(resource_type: 'Product').map(&:resource_id))
    end

    def licenses?
      licenses.present?
    end

    def licenses
      License.where(id: grants.where(credential_type: 'License').map(&:credential_id))
    end

    def grants?
      grants.present?
    end

    def grants
      Checkpoint::DB::Grant.where(agent_type: agent_type.to_s, agent_id: agent_id.to_s)
    end
  end
end
