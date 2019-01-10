# frozen_string_literal: true

class Guest < User
  def name
    return super unless /guest\@fulcrum\.org/i.match?(user_key)
    'member@' + (institutions.first&.name || institutions.first&.identifier || 'institution')
  end

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
