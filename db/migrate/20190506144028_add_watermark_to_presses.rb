class AddWatermarkToPresses < ActiveRecord::Migration[5.1]
  def change
    add_column :presses, :watermark, :boolean, :default => false
  end
end
