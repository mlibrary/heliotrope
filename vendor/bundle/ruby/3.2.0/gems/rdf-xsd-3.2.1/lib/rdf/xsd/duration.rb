require 'time'
require 'date'

module RDF; class Literal
  ##
  # A duration literal.
  #
  # `duration` is a datatype that represents durations of time.  The concept of duration being captured is drawn from those of [ISO 8601](https://www.w3.org/TR/xmlschema11-2/#ISO8601), specifically durations without fixed endpoints.
  #
  # @see   https://www.w3.org/TR/xmlschema11-2/#duration
  class Duration < Literal
    DATATYPE = RDF::XSD.duration
    GRAMMAR  = %r(\A
      (?<si>-)?
      P(?:(?:(?:(?:(?<yr>\d+)Y)(?:(?<mo>\d+)M)?(?:(?<da>\d+)D)?)
          |  (?:(?:(?<mo>\d+)M)(?:(?<da>\d+)D)?)
          |  (?:(?<da>\d+)D)
          )
          (?:T(?:(?:(?:(?<hr>\d+)H)(?:(?<mi>\d+)M)?(?:(?<se>\d+(?:\.\d+)?)S)?)
              |  (?:(?:(?<mi>\d+)M)(?:(?<se>\d+(?:\.\d+)?)S)?)
              |  (?:(?<se>\d+(?:\.\d+)?)S)
              )
          )?
       |(?:T(?:(?:(?:(?<hr>\d+)H)(?:(?<mi>\d+)M)?(?:(?<se>\d+(?:\.\d+)?)S)?)
            |  (?:(?:(?<mi>\d+)M)(?:(?<se>\d+(?:\.\d+)?)S)?)
            |   (?:(?<se>\d+(?:\.\d+)?)S)
            )
        )
       )
    \z)x.freeze

    ##
    # Creates a new Duration instance.
    #
    # * Given a `String`, parse as `xsd:duration` into months and seconds
    # * Given a `Hash` containing any of `:yr`, `:mo`, :da`, `:hr`, `:mi` and `:si`, it is transformed into months and seconds
    # * Given a Rational, the result is interpreted as days, hours, minutes, and seconds.
    # * Given an Integer, the result is interpreted as years and months.
    # * Object representation is the `Array(months, seconds)`
    #
    # @param  [Literal::Duration, Hash, Array, Literal::Numeric, #to_s] value
    #   If provided an Array, it is the same as the object form of this literal, an array of two integers, the first of which may be negative.
    # @param [String]  lexical (nil)
    #   Supplied lexical representation of this literal,
    #   otherwise it comes from transforming `value` to a string form..
    # @param [URI]     datatype (nil)
    # @param [Hash{Symbol => Object}] options other options passed to `RDF::Literal#initialize`.
    # @option options [Boolean] :validate (false)
    # @option options [Boolean] :canonicalize (false)
    def initialize(value, datatype: nil, lexical: nil, **options)
      super
      @object   = case value
      when Hash
        months = value[:yr].to_i * 12 + value[:mo].to_i
        seconds = value[:da].to_i * 3600 * 24 +
                  value[:hr].to_i * 3600 +
                  value[:mi].to_i * 60 +
                  value[:se].to_f

        if value[:si]
          if months != 0
            months = -months
          else
            seconds = -seconds
          end
        end
        [months, seconds]
      when Rational
        [0, value * 24 * 3600]
      when Integer, ::Integer
        [value.to_i, 0]
      when Literal::Duration then value.object
      when Array then    value
      else               parse(value.to_s)
      end
    end

    ##
    # Converts this literal into its canonical lexical representation.
    #
    # @return [Literal] `self`
    # @see    https://www.w3.org/TR/xmlschema11-2/#dateTime
    def canonicalize!
      @string = @humanize = @hash = nil
      self.to_s  # side-effect
      self
    end

    ##
    # Returns `true` if the value adheres to the defined grammar of the
    # datatype.
    #
    # Special case for date and dateTime, for which '0000' is not a valid year
    #
    # @return [Boolean]
    def valid?
      !!value.match?(self.class.const_get(:GRAMMAR))
    end

    ##
    # Returns a hash representation.
    #
    # @return [Hash]
    def to_h
      @hash ||= {
        si: ('-' if (@object.first == 0 ? @object.last : @object.first) < 0),
        yr: (@object.first.abs / 12),
        mo: (@object.first.abs % 12),
        da: (@object.last.abs.to_i / (3600 * 24)),
        hr: ((@object.last.abs.to_i / 3600) % 24),
        mi: ((@object.last.abs.to_i / 60) % 60),
        se: sec_str.to_f
      }
    end

    ##
    # Returns the value as a string.
    #
    # @return [String]
    def to_s
      @string ||= begin
        hash = to_h
        str = (@object.first == 0 ? @object.last : @object.first) < 0 ? '-P' : 'P'
        hash = to_h
        str << "%dY" % hash[:yr] if hash[:yr] > 0
        str << "%dM" % hash[:mo] if hash[:mo] > 0
        str << "%dD" % hash[:da] if hash[:da] > 0
        str << "T" if (hash[:hr] + hash[:mi] + hash[:se]) > 0
        str << "%dH" % hash[:hr] if hash[:hr] > 0
        str << "%dM" % hash[:mi] if hash[:mi] > 0
        str << sec_str + 'S' if hash[:se] > 0
        # Ensure some legal representation
        if str.end_with?('P')
          is_a?(Literal::YearMonthDuration) ? 'P0M' : 'PT0S'
        else
          str
        end
      end
    end

    def plural(v, str)
      "#{v} #{str}#{v.to_i == 1 ? '' : 's'}" if v
    end
    
    ##
    # Returns a human-readable value for the interval
    def humanize(lang = :en)
      @humanize ||= {}
      @humanize[lang] ||= begin
        # Just english, for now
        return "Invalid duration #{value.to_s.inspect}" unless valid?

        md = value.match(GRAMMAR)
        ar = []
        ar << plural(md[:yr], "year") if md[:yr]
        ar << plural(md[:mo], "month") if md[:mo]
        ar << plural(md[:da], "day") if md[:da]
        ar << plural(md[:hr], "hour") if md[:hr]
        ar << plural(md[:mi], "minute") if md[:mi]
        ar << plural(md[:se], "second") if md[:se]
        last = ar.pop
        first = ar.join(" ")
        res = first.empty? ? last : "#{first} and #{last}"
        md[:si] == '-' ? "#{res} ago" : res
      end
    end

    ##
    # Returns `true` if `self` and `other` are durations of the same length.
    #
    # From the XQuery function [op:duration-equal](https://www.w3.org/TR/xpath-functions/#func-duration-equal).
    #
    # @see https://www.w3.org/TR/xpath-functions/#func-duration-equal
    def ==(other)
      # If lexically invalid, use regular literal testing
      return super unless self.valid?

      other.is_a?(Literal::Duration) && other.valid? ? @object == other.object : super
    end

    # Years
    #
    # From the XQuery function [fn:years-from-duration](https://www.w3.org/TR/xpath-functions/#func-years-from-duration).
    #
    # @return [Integer]
    # @see https://www.w3.org/TR/xpath-functions/#func-years-from-duration
    def years; Integer.new(to_h[:yr] * (to_h[:si] ? -1 : 1)); end

    # Months
    #
    # From the XQuery function [fn:months-from-duration](https://www.w3.org/TR/xpath-functions/#func-months-from-duration).
    #
    # @return [Integer]
    # @see https://www.w3.org/TR/xpath-functions/#func-months-from-duration
    def months; Integer.new(to_h[:mo] * (to_h[:si] ? -1 : 1)); end

    # Days
    #
    # From the XQuery function [fn:days-from-duration](https://www.w3.org/TR/xpath-functions/#func-days-from-duration).
    #
    # @return [Integer]
    # @see https://www.w3.org/TR/xpath-functions/#func-days-from-duration
    def days; Integer.new(to_h[:da] * (to_h[:si] ? -1 : 1)); end

    # Hours
    #
    # From the XQuery function [fn:hours-from-duration](https://www.w3.org/TR/xpath-functions/#func-hours-from-duration).
    #
    # @return [Integer]
    # @see https://www.w3.org/TR/xpath-functions/#func-hours-from-duration
    def hours; Integer.new(to_h[:hr] * (to_h[:si] ? -1 : 1)); end

    # Minutes
    #
    # From the XQuery function [fn:minutes-from-duration](https://www.w3.org/TR/xpath-functions/#func-minutes-from-duration).
    #
    # @return [Integer]
    # @see https://www.w3.org/TR/xpath-functions/#func-minutes-from-duration
    def minutes; Integer.new(to_h[:mi] * (to_h[:si] ? -1 : 1)); end

    # Seconds
    #
    # From the XQuery function [fn:seconds-from-duration](https://www.w3.org/TR/xpath-functions/#func-seconds-from-duration).
    #
    # @return [Decimal]
    # @see https://www.w3.org/TR/xpath-functions/#func-seconds-from-duration
    def seconds; Decimal.new(to_h[:se] * (to_h[:si] ? -1 : 1)); end

  private
    # Reverse convert from XSD version of duration
    # XSD allows -P1111Y22M33DT44H55M66.666S with any combination in regular order
    # We assume 1M == 30D, but are out of spec in this regard
    # We only output up to hours
    #
    # @param [String] value XSD formatted duration
    # @return [Duration]
    def parse(value)
      return [0, 0] unless md = value.to_s.match(GRAMMAR)

      months  = md[:yr].to_i * 12 + md[:mo].to_i
      seconds = md[:da].to_i * 3600 * 24 +
                md[:hr].to_i * 3600 +
                md[:mi].to_i * 60 +
                md[:se].to_f

      if md[:si]
        if months != 0
          months = -months
        else
          seconds = -seconds
        end
      end

      [months, seconds]
    end
    
    def sec_str
      sec = @object.last.abs % 60
      ((sec.truncate == sec ? "%d" : "%2.3f") % sec).sub(/(\.[1-9]+)0+$/, '\1')
    end
  end # Duration

  ##
  # A `YearMonthDuration` literal.
  #
  # `yearMonthDuration` is a datatype ·derived· from `xsd:duration` by restricting its ·lexical representations· to instances of `yearMonthDurationLexicalRep`.  The ·value space· of `yearMonthDuration` is therefore that of `duration` restricted to those whose ·seconds· property is 0.  This results in a `duration` datatype which is totally ordered.
  #
  # @see   https://www.w3.org/TR/xmlschema11-2/#yearMonthDuration
  class YearMonthDuration < Duration
    DATATYPE = RDF::XSD.yearMonthDuration
    GRAMMAR  = %r(\A
      (?<si>-)?
      P(?:(?:(?:(?:(?<yr>\d+)Y)(?:(?<mo>\d+)M)?)
          |  (?:(?:(?<mo>\d+)M))
          )
       )
    \z)x.freeze

    ##
    # Returns the sum of two xs:yearMonthDuration values.
    #
    # From the XQuery function [op:add-yearMonthDurations](https://www.w3.org/TR/xpath-functions/#func-add-yearMonthDurations).
    #
    # @param [YearMonthDuration] other
    # @return [YearMonthDuration] 
    # @see https://www.w3.org/TR/xpath-functions/#func-add-yearMonthDurations
    def +(other)
      return type_error("#{other.inspect} is not a valid YearMonthDuration") unless other.is_a?(Literal::YearMonthDuration) && other.valid?
      self.class.new([object.first + other.object.first, 0])
    end

    ##
    # Returns the result of subtracting one xs:yearMonthDuration value from another.
    #
    # From the XQuery function [op:subtract-yearMonthDurations](https://www.w3.org/TR/xpath-functions/#func-subtract-yearMonthDurations).
    #
    # @param [YearMonthDuration] other
    # @return [YearMonthDuration] 
    # @see https://www.w3.org/TR/xpath-functions/#func-subtract-yearMonthDurations
    def -(other)
      return type_error("#{other.inspect} is not a valid YearMonthDuration") unless other.is_a?(Literal::YearMonthDuration) && other.valid?
      self.class.new([object.first - other.object.first, 0])
    end

    ##
    # Returns the result of multiplying the value of self by `other`. The result is rounded to the nearest month.
    #
    # From the XQuery function [op:multiply-yearMonthDuration](https://www.w3.org/TR/xpath-functions/#func-multiply-yearMonthDuration).
    #
    # @param [Literal::Numeric, ::Numeric, DayTimeDuration] other
    # @return [YearMonthDuration] 
    # @see https://www.w3.org/TR/xpath-functions/#func-multiply-yearMonthDuration
    def *(other)
      return type_error("#{other.inspect} is not a valid Numeric") unless (other.is_a?(::Numeric) || other.is_a?(Literal::Numeric))
      self.class.new([(object.first * other.to_f).round, 0])
    end

    ##
    # Returns the result of dividing the value of self by `other`. The result is rounded to the nearest month.
    #
    # From the XQuery functions [op:divide-yearMonthDuration](https://www.w3.org/TR/xpath-functions/#func-divide-yearMonthDuration) and [op:divide-yearMonthDuration-by-yearMonthDuration](https://www.w3.org/TR/xpath-functions/#func-divide-yearMonthDuration-by-yearMonthDuration).
    #
    # @param [Literal::Numeric, ::Numeric, YearMonthDuration] other
    # @return [YearMonthDuration, Decimal] 
    # @see https://www.w3.org/TR/xpath-functions/#func-divide-yearMonthDuration
    # @see https://www.w3.org/TR/xpath-functions/#func-divide-yearMonthDuration-by-yearMonthDuration
    def /(other)
      case other
      when Literal::YearMonthDuration
        return type_error("#{other.inspect} is not a valid YearMonthDuration or Numeric") unless other.valid?
        Decimal.new(object.first / other.object.first.to_f)
      when Literal::Numeric, ::Numeric
        self.class.new([(object.first / other.to_f).round, 0])
      else
        type_error("#{other.inspect} is not a valid YearMonthDuration or Numeric")
      end
    end

    ##
    # Compares this literal to `other` for sorting purposes.
    #
    # From the XQuery function [op:yearMonthDuration-greater-than](https://www.w3.org/TR/xpath-functions/#func-yearMonthDuration-less-than).
    #
    # @param [Literal::YearMonthDuration] other
    # @return [Boolean] `true` if less than other for defined datatypes
    # @see https://www.w3.org/TR/xpath-functions/#func-yearMonthDuration-less-than
    # @see https://www.w3.org/TR/xpath-functions/#func-yearMonthDuration-greater-than
    def <=>(other)
      return type_error("#{other.inspect} is not a valid YearMonthDuration") unless other.is_a?(Literal::YearMonthDuration) && other.valid?
      @object.first <=> other.object.first
    end

    ##
    # Converts the dayTimeDuration into rational seconds.
    #
    # @return [Rational]
    def to_i
      object.first.to_i
    end
  end # YearMonthDuration

  ##
  # A DayTimeDuration literal.
  #
  # `dayTimeDuration` is a datatype ·derived· from `duration` by restricting its ·lexical representations· to instances of `dayTimeDurationLexicalRep`. The ·value space· of `dayTimeDuration` is therefore that of `duration` restricted to those whose ·months· property is 0.  This results in a duration datatype which is totally ordered.
  #
  # @see   https://www.w3.org/TR/xmlschema11-2/#dayTimeDuration
  class DayTimeDuration < Duration
    DATATYPE = RDF::XSD.dayTimeDuration
    GRAMMAR  = %r(\A
      (?<si>-)?
      P(?:(?:(?:(?<da>\d+)D)
          )
          (?:T(?:(?:(?:(?<hr>\d+)H)(?:(?<mi>\d+)M)?(?<se>\d+(?:\.\d+)?S)?)
              |  (?:(?:(?<mi>\d+)M)(?:(?<se>\d+(?:\.\d+)?)S)?)
              |  (?:(?<se>\d+(?:\.\d+)?)S)
              )
          )?
       |(?:T(?:(?:(?:(?<hr>\d+)H)(?:(?<mi>\d+)M)?(?<se>\d+(?:\.\d+)?S)?)
            |  (?:(?:(?<mi>\d+)M)(?:(?<se>\d+(?:\.\d+)?)S)?)
            |   (?:(?<se>\d+(?:\.\d+)?)S)
            )
        )
       )
    \z)x.freeze

    ##
    # Returns the sum of two xs:dayTimeDuration values.
    #
    # From the XQuery function [op:add-dayTimeDurations](https://www.w3.org/TR/xpath-functions/#func-add-dayTimeDurations).
    #
    # @param [DayTimeDuration] other
    # @return [DayTimeDuration] 
    # @see https://www.w3.org/TR/xpath-functions/#func-add-dayTimeDurations
    def +(other)
      return type_error("#{other.inspect} is not a valid DayTimeDuration") unless other.is_a?(Literal::DayTimeDuration) && other.valid?
      self.class.new([0, object.last + other.object.last])
    end

    ##
    # Returns the result of subtracting one xs:dayTimeDuration value from another.
    #
    # From the XQuery function [op:subtract-dayTimeDurationss](https://www.w3.org/TR/xpath-functions/#func-subtract-dayTimeDurations).
    #
    # @param [DayTimeDuration] other
    # @return [DayTimeDuration] 
    # @see https://www.w3.org/TR/xpath-functions/#func-subtract-dayTimeDurations
    def -(other)
      return type_error("#{other.inspect} is not a valid DayTimeDuration")  unless other.is_a?(Literal::DayTimeDuration) && other.valid?
      self.class.new([0, object.last - other.object.last])
    end

    ##
    # Returns the result of multiplying the value of self by `other`. The result is rounded to the nearest month.
    #
    # From the XQuery function [op:multiply-dayTimeDuration](https://www.w3.org/TR/xpath-functions/#func-multiply-dayTimeDuration).
    #
    # @param [Literal::Numeric, ::Numeric] other
    # @return [DayTimeDuration] 
    # @see https://www.w3.org/TR/xpath-functions/#func-multiply-dayTimeDuration
    def *(other)
      return type_error("#{other.inspect} is not a valid Numeric")  unless (other.is_a?(::Numeric) || other.is_a?(Literal::Numeric))
      self.class.new([0, object.last * other.to_f])
    end

    ##
    # Returns the result of dividing the value of self by `other`. The result is rounded to the nearest month.
    #
    # From the XQuery functions [op:divide-yearMonthDuration](https://www.w3.org/TR/xpath-functions/#func-divide-dayTimeDuration) and [op:divide-yearMonthDuration-by-yearMonthDuration](https://www.w3.org/TR/xpath-functions/#func-divide-dayTimeDuration-by-dayTimeDuration).
    #
    # @param [Literal::Numeric, ::Numeric, DayTimeDuration] other
    # @return [DayTimeDuration, Decimal] 
    # @see https://www.w3.org/TR/xpath-functions/#func-divide-dayTimeDuration
    # @see https://www.w3.org/TR/xpath-functions/#func-divide-dayTimeDuration-by-dayTimeDuration
    def /(other)
      case other
      when DayTimeDuration
        return type_error("#{other.inspect} is not a valid DayTimeDuration or Numeric")  unless other.valid?
        Decimal.new(object.last / other.object.last.to_f)
      when Literal::Numeric, ::Numeric
        self.class.new([0, object.last / other.to_f])
      else
        type_error("#{other.inspect} is not a valid DayTimeDuration or Numeric") 
      end
    end

    ##
    # Compares this literal to `other` for sorting purposes.
    #
    # From the XQuery function [op:dayTimeDuration-less-than](https://www.w3.org/TR/xpath-functions/#func-dayTimeDuration-less-than).
    #
    # @param [DayTimeDuration] other
    # @return [Boolean] `true` if less than other for defined datatypes
    # @see https://www.w3.org/TR/xpath-functions/#func-dayTimeDuration-less-than
    # @see https://www.w3.org/TR/xpath-functions/#func-dayTimeDuration-greater-than
    def <=>(other)
      return type_error("#{other.inspect} is not a valid DayTimeDuration") unless other.is_a?(Literal::DayTimeDuration) && other.valid?
      @object.last <=> other.object.last
    end

    ##
    # Converts the dayTimeDuration into rational seconds.
    #
    # @return [Rational]
    def to_r
      Rational(object.last) / (24 * 3600)
    end
  end # DayTimeDuration
end; end # RDF::Literal
