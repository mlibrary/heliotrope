class AddProductRefToLicenses < ActiveRecord::Migration[5.2]
  def change
    add_reference :licenses, :product, foreign_key: true
  end
end
