class CreateInstitutionAffiliations < ActiveRecord::Migration[5.2]
  def change
    create_table :institution_affiliations do |t|
      t.references :institution, foreign_key: true
      t.integer :dlps_institution_id
      t.string :affiliation

      t.timestamps
    end
  end
end
