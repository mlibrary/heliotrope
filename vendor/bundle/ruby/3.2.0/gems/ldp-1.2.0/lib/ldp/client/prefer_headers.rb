module Ldp
  class PreferHeaders
    attr_reader :headers_string

    def initialize(headers_string = "")
      @headers_string = headers_string
    end

    def omit
      @omit ||= options["omit"] || []
    end

    def include
      @include ||= options["include"] || []
    end

    def return
      @return ||= options["return"].first || ""
    end

    def include=(vals)
      @include = Array(vals)
      serialize
    end

    def omit=(vals)
      @omit = Array(vals)
      serialize
    end

    def return=(vals)
      @return = Array(vals).first
      serialize
    end

    def to_s
      headers_string.to_s
    end

    private

    def serialize
      head_string = []
      unless self.return.empty?
        head_string << "return=#{self.return}"
      end
      unless omit.empty?
        head_string << "omit=\"#{omit.join(" ")}\""
      end
      unless self.include.empty?
        head_string << "include=\"#{self.include.join(" ")}\""
      end
      @headers_string = head_string.join("; ")
    end

    def options
      headers_string.gsub('"', "")
                    .split(";")
                    .map { |x| x.strip.split("=") }
                    .map { |x| { x[0] => x[1].split(" ") } }
                    .inject({}, &:merge)
    end
  end
end
