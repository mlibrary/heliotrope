# frozen_string_literal: true

class Entity
  include ActiveModel::Model

  TYPES = %w[any email epub].freeze

  attr_reader :type, :id, :identifier, :name

  validates :type, presence: true, allow_blank: false, inclusion: { in: TYPES }
  validates :id, presence: true, allow_blank: false

  def initialize(identifier, name, type: :any, id: :any)
    @type = type&.to_s
    @id = id&.to_s
    @identifier = identifier&.to_s
    @name = name&.to_s
  end

  def self.null_object
    EntityNullObject.send(:new)
  end

  def null_object?
    is_a? EntityNullObject
  end
end

class EntityNullObject < Entity
  private_class_method :new

  private

    def initialize
      @type = 'null_type'
      @id = 'null_id'
      @identifier = 'null_type:null_id'
      @name = 'EntityNullObject'
    end
end
