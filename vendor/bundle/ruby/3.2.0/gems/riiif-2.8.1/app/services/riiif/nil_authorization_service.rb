module Riiif
  class NilAuthorizationService
    def initialize(_controller); end

    def can?(_action, _object)
      true
    end
  end
end
