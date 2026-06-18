# frozen_string_literal: true

class AddShowAuthorBiosToPress < ActiveRecord::Migration[5.2]
  def change
    add_column :presses, :show_author_bios, :boolean, after: :interval, default: false
  end
end
