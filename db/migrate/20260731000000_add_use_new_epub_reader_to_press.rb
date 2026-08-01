# frozen_string_literal: true

class AddUseNewEpubReaderToPress < ActiveRecord::Migration[6.1]
  def change
    add_column :presses, :use_new_epub_reader, :boolean, null: false, default: false
  end
end
