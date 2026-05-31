# frozen_string_literal: true
module Valkyrie
  # A simple ID class to keep IDs distinguished from strings
  # In order for an object to be queryable via joins, it needs
  # to be added as a reference via a Valkyrie::ID rather than just a string ID.
  class ID
    attr_reader :id
    delegate :empty?, to: :id
    def initialize(id)
      @id = id.to_s
    end

    ##
    # @return [String]
    def to_s
      to_str
    end

    ##
    # @return [String]
    def to_str
      id
    end

    delegate :hash, to: :state

    def eql?(other)
      other == to_str
    end
    alias == eql?

    protected

    def state
      [@id]
    end
  end
end
