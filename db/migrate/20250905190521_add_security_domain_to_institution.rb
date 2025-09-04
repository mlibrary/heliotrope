class AddSecurityDomainToInstitution < ActiveRecord::Migration[6.1]
  def change
    add_column :institutions, :security_domain, :text, after: :entity_id
  end
end
