# frozen_string_literal: true

class Guest < User
  def save(*_args, &_block)
    false
  end

  def save!(*_args, &_block)
    raise(ActiveRecord::RecordNotSaved.new("Failed to save the record", self))
  end

  def agent_type
    :Guest
  end

  def agent_id
    user_key # email for now because of devise
  end
end
