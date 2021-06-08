class AddFieldsToInstitutions < ActiveRecord::Migration[5.2]
  def change
    add_column :institutions, :catalog_url, :string
    add_column :institutions, :link_resolver_url, :string
    add_column :institutions, :logo_path, :string
  end
end
