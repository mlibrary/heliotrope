module Noid
  class Template
    attr_reader :template, :prefix, :generator, :characters

    VALID_PATTERN = /\A(.*)\.([rsz])([ed]+)(k?)\Z/

    # @param [String] template A Template is a coded string of the form Prefix.Mask that governs how identifiers will be minted.
    def initialize(template)
      @template = template
      parse!
    end

    def mint(n)
      str = prefix
      str += n2xdig(n)
      str += checkdigit(str) if checkdigit?
      str
    end

    ##
    # Is the string valid against this template string and checksum?
    # @param [String] str
    # @return bool
    def valid?(str)
      match = validation_regex.match(str)
      return false if match.nil?
      return checkdigit(match[1]) == match[3] if checkdigit?
      true
    end

    ##
    # calculate a checkdigit for the str
    # @param [String] str
    # @return [String] checkdigit
    def checkdigit(str)
      Noid::XDIGIT[str.split('').map { |x| Noid::XDIGIT.index(x).to_i }.each_with_index.map { |n, idx| n * (idx + 1) }.inject { |sum, n| sum + n } % Noid::XDIGIT.length]
    end

    ##
    # minimum sequence value
    def min
      @min ||= 0
    end

    def to_s
      template
    end

    def ==(other)
      return false unless other.is_a? Noid::Template
      template == other.template
    end

    ##
    # maximum sequence value for the template
    def max
      @max ||= if generator == 'z'
                 nil
               else
                 size_list.inject(1) { |total, x| total * x }
               end
    end

    protected

    ##
    # A noid has the structure (prefix)(code)(checkdigit)
    # the regexp has the following captures
    #  1 - the prefix and the code
    #  2 - the changing id characters (not the prefix and not the checkdigit)
    #  3 - the checkdigit, if there is one. This field is missing if there is no checkdigit
    def validation_regex
      @validation_regex ||= begin
                              character_pattern = ''
                              # the first character in the mask after the type character is the most significant
                              # acc. to the Noid spec (p.9):
                              # https://wiki.ucop.edu/display/Curation/NOID?preview=/16744482/16973835/noid.pdf
                              character_pattern += character_to_pattern(character_list.first) + "*" if generator == 'z'
                              character_pattern += character_list.map { |c| character_to_pattern(c) }.join

                              %r{\A(#{Regexp.escape(prefix)}(#{character_pattern}))(#{character_to_pattern('k') if checkdigit?})\Z}
                            end
    end

    ##
    # parse template and put the results into instance variables
    # raise an exception if there is a parse error
    def parse!
      match = VALID_PATTERN.match(template)
      raise Noid::TemplateError, "Malformed noid template '#{template}'" unless match
      @prefix = match[1]
      @generator = match[2]
      @characters = match[3]
      @checkdigit = (match[4] == 'k')
    end

    def xdigit_pattern
      @xdigit_pattern ||= '[' + Noid::XDIGIT.join('') + ']'
    end

    def character_to_pattern(c)
      case c
      when 'e', 'k'
        xdigit_pattern
      when 'd'
        '\d'
      else
        ''
      end
    end

    ##
    # Return a list giving the number of possible characters at each position
    def size_list
      @size_list ||= character_list.map { |c| character_space(c) }
    end

    def character_list
      characters.split('')
    end

    def mask
      generator + characters
    end

    def checkdigit?
      @checkdigit
    end

    ##
    # total size of a given template character value
    # @param [String] c
    def character_space(c)
      case c
      when 'e'
        Noid::XDIGIT.length
      when 'd'
        10
      end
    end

    ##
    # convert a minter position to a noid string under this template
    # @param [Integer] n
    # @return [String]
    def n2xdig(n)
      xdig = size_list.reverse.map { |size|
        value = n % size
        n /= size
        Noid::XDIGIT[value]
      }.compact.join('')

      if generator == 'z'
        size = size_list.last
        while n > 0
          value = n % size
          n /= size
          xdig += Noid::XDIGIT[value]
        end
      end

      raise 'Exhausted noid sequence pool' if n > 0

      xdig.reverse
    end
  end
end
