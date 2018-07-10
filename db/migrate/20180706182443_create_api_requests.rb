class CreateAPIRequests < ActiveRecord::Migration[5.1]
  def change
    create_table :api_requests do |t|
      t.references :user, foreign_key: true, type: :integer
      t.string :action
      t.string :path
      t.string :params
      t.integer :status
      t.string :exception

      t.timestamps
    end
  end
end
