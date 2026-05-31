# frozen_string_literal: true

class RenameMinterStateRandomToRand < ActiveRecord::Migration[4.2]
  def change
    rename_column :minter_states, :random, :rand
  end
end
