# frozen_string_literal: true

class Customer
  include ActiveModel::Model

  attr_reader :id

  validates :id, presence: true, allow_blank: false

  def initialize(id)
    @id = id
  end

  def self.null_object
    CustomerNullObject.send(:new)
  end

  def null_object?
    is_a? CustomerNullObject
  end

  def save(*_args, &_block)
    false
  end

  def save!(*_args, &_block)
    raise(ActiveRecord::RecordNotSaved.new("Failed to save record", self))
  end
end

class CustomerNullObject < Customer
  private_class_method :new

  private
    def initialize
      super(nil)
    end
end
