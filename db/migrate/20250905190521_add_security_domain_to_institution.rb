class AddSecurityDomainToInstitution < ActiveRecord::Migration[6.1]
  def change
    add_column :institutions, :security_domain, :string, after: :entity_id, default: ""
  end
end
