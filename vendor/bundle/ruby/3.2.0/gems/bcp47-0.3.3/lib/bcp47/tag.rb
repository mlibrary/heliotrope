module BCP47
  class Tag
    attr_accessor :language, :region

    def initialize(code)
      @code     = code
      @language = Language.identify(code)
      @region   = Region.identify(code)
    end

    def codes
      subtags.map(&:code)
    end

    def subtags
      [language, region].compact
    end
  end
end
