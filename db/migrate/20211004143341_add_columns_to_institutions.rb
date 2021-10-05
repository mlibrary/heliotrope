class AddColumnsToInstitutions < ActiveRecord::Migration[5.2]
  def change
    add_column :institutions, :display_name, :string
    add_column :institutions, :location, :string
    add_column :institutions, :ror_id, :string
  end
end
