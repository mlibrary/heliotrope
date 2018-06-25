#Add footer block b to presses db
class AddFooterBlockToPresses < ActiveRecord::Migration[5.1]
  def change
    add_column(:presses, :footer_block_b, :text)
  end
end
