# frozen_string_literal: true

class AddUniqueIndexesForUniquenessValidations < ActiveRecord::Migration[6.1]
  def change
    add_index :ebook_table_of_contents_caches, :noid, unique: true

    change_table :featured_representatives, bulk: true do |t|
      t.index :file_set_id, unique: true
      t.index %i[work_id kind], unique: true
    end

    change_table :presses, bulk: true do |t|
      t.index :name, unique: true
      t.index :subdomain, unique: true
      t.index :press_url, unique: true
    end
  end
end
