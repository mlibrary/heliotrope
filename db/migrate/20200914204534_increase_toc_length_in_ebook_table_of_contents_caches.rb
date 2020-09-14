class IncreaseTocLengthInEbookTableOfContentsCaches < ActiveRecord::Migration[5.2]
  def change
    change_column :ebook_table_of_contents_caches, :toc, :mediumtext
  end
end
