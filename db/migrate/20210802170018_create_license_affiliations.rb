class CreateLicenseAffiliations < ActiveRecord::Migration[5.2]
  def change
    create_table :license_affiliations do |t|
      t.references :license, foreign_key: true
      t.string :affiliation

      t.timestamps
    end
  end
end
