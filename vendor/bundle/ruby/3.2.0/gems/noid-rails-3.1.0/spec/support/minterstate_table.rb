# frozen_string_literal: true

module MinterStateHelper
  # Simple truncation is not enough, since we also need seed data
  def reset_minter_state_table
    MinterState.destroy_all
    MinterState.create!(
      namespace: 'default',
      template: '.reeddeeddk',
      seq: 0
    )
  end
end
