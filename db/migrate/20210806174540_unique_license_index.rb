class UniqueLicenseIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :licenses, [:type, :licensee_type, :licensee_id, :product_id], unique: true, name: 'index_licenses_on_all_fields'
  end
end
