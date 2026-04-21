class CreateCounterSummaries < ActiveRecord::Migration[6.1]
  def change
    create_table :counter_summaries, options: 'CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci' do |t|
      t.string :monograph_noid, null: false
      t.integer :month, null: false
      t.integer :year, null: false

      # Monthly metrics
      t.integer :total_item_requests_month, default: 0, null: false
      t.integer :total_item_investigations_month, default: 0, null: false
      t.integer :unique_item_requests_month, default: 0, null: false
      t.integer :unique_item_investigations_month, default: 0, null: false

      # Lifetime metrics
      t.integer :total_item_requests_life, default: 0, null: false
      t.integer :total_item_investigations_life, default: 0, null: false
      t.integer :unique_item_requests_life, default: 0, null: false
      t.integer :unique_item_investigations_life, default: 0, null: false

      t.timestamps
    end

    add_index :counter_summaries, [:monograph_noid, :month, :year], unique: true, name: 'index_counter_summary_on_noid_month_year'
    add_index :counter_summaries, [:year, :month], name: 'index_counter_summary_on_year_month'
  end
end
