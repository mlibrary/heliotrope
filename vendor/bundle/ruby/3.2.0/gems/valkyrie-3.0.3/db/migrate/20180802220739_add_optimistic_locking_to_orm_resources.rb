# frozen_string_literal: true
class AddOptimisticLockingToOrmResources < ActiveRecord::Migration[5.1]
  def change
    add_column :orm_resources, :lock_version, :integer
  end
end
