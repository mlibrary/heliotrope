# frozen_string_literal: true

class Entity
  include ActiveModel::Model

  TYPES = %w[email epub].freeze

  attr_reader :type, :identifier

  validates :type, presence: true, allow_blank: false, inclusion: { in: TYPES }
  validates :identifier, presence: true, allow_blank: false

  def initialize(type:, identifier:)
    @type = type.to_s
    @identifier = identifier.to_s
  end

  def self.null_object
    EntityNullObject.send(:new)
  end

  def null_object?
    is_a? EntityNullObject
  end

  def id
    "#{type}:#{identifier}"
  end
end

class EntityNullObject < Entity
  private_class_method :new

  private

    def initialize
      @type = :null.to_s
      @identifier = :null.to_s
    end
end
