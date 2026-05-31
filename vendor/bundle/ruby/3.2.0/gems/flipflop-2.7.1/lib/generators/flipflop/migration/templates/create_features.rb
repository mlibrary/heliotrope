class CreateFeatures < ActiveRecord::Migration<%= Rails.version >= "5" ? "[#{ActiveRecord::Migration.current_version}]" : "" %>
  def change
    create_table :flipflop_features do |t|
      t.string :key, null: false
      t.boolean :enabled, null: false, default: false

      t.timestamps null: false
    end
  end
end
