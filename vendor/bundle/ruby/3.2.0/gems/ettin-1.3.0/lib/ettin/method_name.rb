# frozen_string_literal: true

module Ettin

  # A class for analyzing and manipulating a method's name
  class MethodName
    ASSIGN_CHAR = "="
    BANG_CHAR = "!"

    def initialize(method)
      @method = method.to_s
    end

    def to_sym
      method.to_sym
    end

    def to_s
      method
    end

    def clean
      @clean ||= if bang? || assignment?
        method.chop
      else
        method
      end.to_sym
    end

    def bang?
      method[-1] == BANG_CHAR
    end

    def assignment?
      method[-1] == ASSIGN_CHAR
    end

    private

    attr_reader :method
  end
end
