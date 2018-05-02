class AddIdentifierToInstitutions < ActiveRecord::Migration[5.1]
  def change
    add_column :institutions, :identifier, :string
  end
end
