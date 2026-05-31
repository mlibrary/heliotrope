# frozen_string_literal: true
module ActiveEncode #:nodoc:
  class NotFound < RuntimeError; end
  class NotRunningError < RuntimeError; end
  class CancelError < RuntimeError; end
end
