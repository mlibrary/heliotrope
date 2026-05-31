# frozen_string_literal: true
module DropboxApi::MiddleWare
  class Stack
    def initialize
      @prependable, @appendable = [], []
    end

    def prepend(&block)
      @prependable << block
    end

    def append(&block)
      @appendable << block
    end

    def adapter=(value)
      @adapter = value
    end

    def apply(connection)
      @prependable.each { |block| block.yield(connection) }
      yield connection
      @appendable.each { |block| block.yield(connection) }

      # Adapter must be the last middleware configured
      connection.adapter(@adapter || Faraday.default_adapter)
    end
  end
end
