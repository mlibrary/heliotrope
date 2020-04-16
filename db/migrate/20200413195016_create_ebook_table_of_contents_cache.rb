class CreateEbookTableOfContentsCache < ActiveRecord::Migration[5.1]
  def change
    create_table :ebook_table_of_contents_caches do |t|
      t.string :noid
      t.text :toc
    end
  end
end
