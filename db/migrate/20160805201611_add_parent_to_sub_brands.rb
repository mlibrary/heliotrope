class AddParentToSubBrands < ActiveRecord::Migration
  # Adds a foreign key to sub_brands from itself.
  # Which is weird.  Consider not being weird.
  def up
    
    add_foreign_key :sub_brands, :sub_brands, column: :parent_id, primary_key: "id"
  end
end
