# frozen_string_literal: true
class CreatePathGinIndex < ActiveRecord::Migration[5.1]
  def change
    add_index :orm_resources, 'metadata jsonb_path_ops', using: :gin
  end
end
