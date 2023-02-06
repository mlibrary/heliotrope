class AddNeedsKbartAndGroupKeyToProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :needs_kbart, :boolean, default: false
    add_column :products, :group_key, :string
  end
end
