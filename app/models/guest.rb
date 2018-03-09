# frozen_string_literal: true

class Guest < User
  def save(*_args, &_block)
    false
  end

  def save!(*_args, &_block)
    raise(ActiveRecord::RecordNotSaved.new("Failed to save the record", self))
  end
end
