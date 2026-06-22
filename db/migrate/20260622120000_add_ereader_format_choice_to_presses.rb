# frozen_string_literal: true

class AddEreaderFormatChoiceToPresses < ActiveRecord::Migration[6.0]
  def change
    add_column :presses, :ereader_format_choice, :boolean, after: :navigation_block, default: false
  end
end
