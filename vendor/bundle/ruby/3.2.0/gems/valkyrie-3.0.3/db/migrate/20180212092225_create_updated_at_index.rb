# frozen_string_literal: true
class CreateUpdatedAtIndex < ActiveRecord::Migration[5.1]
  def change
    add_index :orm_resources, :updated_at
  end
end
