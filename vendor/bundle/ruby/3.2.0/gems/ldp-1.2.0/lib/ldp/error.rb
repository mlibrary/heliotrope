module Ldp
  class Error < StandardError; end

  class HttpError          < RuntimeError; end
  class BadRequest         < HttpError; end # 400
  class NotFound           < HttpError; end # 404
  class Conflict           < HttpError; end # 409
  class Gone               < HttpError; end # 410
  class PreconditionFailed < HttpError; end # 412

  class UnexpectedContentType < RuntimeError; end

  class GraphDifferenceException < Ldp::Error
    attr_reader :diff
    def initialize message, diff
      super(message)
      @diff = diff
    end
  end

  ETagMismatch = PreconditionFailed # deprecation
end
