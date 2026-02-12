class AddDoiPrefixesToPress < ActiveRecord::Migration[6.1]
  def change
    add_column :presses, :doi_prefixes, :string, after: :doi_creation
  end
end
