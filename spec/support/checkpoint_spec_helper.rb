# frozen_string_literal: true

module CheckpointSpecHelper
  def clear_grants_table
    Checkpoint::DB.db[:grants].delete
  end

  def grants_table_count
    Checkpoint::DB::Grant.count
  end

  def grants_table_last
    Checkpoint::DB::Grant.last
  end
end
