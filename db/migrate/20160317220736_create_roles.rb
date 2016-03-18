class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.references :resource, polymorphic: true, index: true
      t.references :user, index: true, foreign_key: true
      t.string :role

      t.timestamps null: false
    end
  end
end
