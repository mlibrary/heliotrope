# frozen_string_literal: true
module Valkyrie
  # A wrapper class for Valkyrie logging. This class attempts to provide
  # tooling that helps improve the communication through-out the stack.
  #
  # In gem development there are several considerations regarding logging.
  #
  # 1) The development on the gem directly, in particular specs
  # 2) The downstream development that leverages the gem, both when specs are
  #    running and when running the downstream processes in a development
  #    environment.
  # 3) The downstream behaviors that are called in production environments.
  #
  # In each of these cases, different considerations regarding logging may be
  # relevant.
  #
  # In the below example,
  #
  # @example
  #   Valkyrie.logger.suppress_logging_for_contexts!("A Named Context") do
  #     # The following will NOT be logged
  #     Valkyrie.logger.warn('Hello', logging_context: "A Named Context")
  #
  #     # The following will be logged
  #     Valkyrie.logger.warn('Hello')
  #   end
  #   # The following will be logged
  #   Valkyrie.logger.warn('Hello', logging_context: "A Named Context")

  class Logging < SimpleDelegator
    # @param logger [Logger] the logger to which we'll delegate messages
    def initialize(logger:)
      @suppressions = {}
      super(logger)
    end

    def warn(*args, logging_context: false, &block)
      super(*args, *block) unless @suppressions.key?(logging_context)
    end

    def error(*args, logging_context: false, &block)
      super(*args, *block) unless @suppressions.key?(logging_context)
    end

    def info(*args, logging_context: false, &block)
      super(*args, *block) unless @suppressions.key?(logging_context)
    end

    def debug(*args, logging_context: false, &block)
      super(*args, *block) unless @suppressions.key?(logging_context)
    end

    def fatal(*args, logging_context: false, &block)
      super(*args, *block) unless @suppressions.key?(logging_context)
    end

    def suppress_logging_for_contexts!(*logging_contexts)
      Array(logging_contexts).each do |logging_context|
        @suppressions[logging_context] = true
      end
      return unless block_given?
      yield
      clear_suppressions!(*logging_contexts)
    end

    def clear_suppressions!(*logging_contexts)
      Array(logging_contexts).each do |logging_context|
        @suppressions.delete(logging_context)
      end
    end
  end
end
