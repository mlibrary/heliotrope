# frozen_string_literal: true

class AddUniqueIndexesForUniquenessValidations < ActiveRecord::Migration[6.1]
  def up
    # A failed schema load or MySQL migration can leave indexes without a migration version.
    add_index :ebook_table_of_contents_caches, :noid, unique: true unless index_exists?(:ebook_table_of_contents_caches, :noid, unique: true)

    %i[name subdomain press_url].each do |column|
      add_index :presses, column, unique: true unless index_exists?(:presses, column, unique: true)
    end
  end

  def down
    %i[name subdomain press_url].each do |column|
      remove_index :presses, column if index_exists?(:presses, column, unique: true)
    end

    remove_index :ebook_table_of_contents_caches, :noid if index_exists?(:ebook_table_of_contents_caches, :noid, unique: true)
  end
end
