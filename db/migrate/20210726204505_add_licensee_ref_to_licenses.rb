class AddLicenseeRefToLicenses < ActiveRecord::Migration[5.2]
  def change
    add_reference :licenses, :licensee, polymorphic: true
  end
end
