# coding: utf-8
require 'rdf'

module RDF; class Literal
  ##
  # dateTimeStamp
  #
  # The dateTimeStamp datatype is ·derived· from dateTime by giving the value required to its explicitTimezone facet. The result is that all values of dateTimeStamp are required to have explicit time zone offsets and the datatype is totally ordered.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#dateTimeStamp
  class DateTimeStamp < RDF::Literal::DateTime
    DATATYPE = RDF::XSD.dateTimeStamp
    GRAMMAR  = %r(\A(-?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?)((?:[\+\-]\d{2}:\d{2})|UTC|GMT|Z)\Z).freeze
    FORMAT   = '%Y-%m-%dT%H:%M:%S'.freeze
  end

  ##
  # gYearMonth represents a specific gregorian month in a specific gregorian year. The value space of gYearMonth is
  # the set of Gregorian calendar months as defined in § 5.2.1 of [ISO 8601]. Specifically, it is a set of one-month
  # long, non-periodic instances e.g. 1999-10 to represent the whole month of 1999-10, independent of how many days this
  # month has.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#gYearMonth
  class YearMonth < RDF::Literal::Date
    DATATYPE = RDF::XSD.gYearMonth
    GRAMMAR  = %r(\A(-?\d{4,}-\d{2})((?:[\+\-]\d{2}:\d{2})|UTC|Z)?\Z).freeze
    FORMAT   = '%Y-%m'.freeze
    
    def initialize(value, datatype: nil, lexical: nil, **options)
      @string = lexical || value.to_s
      object = GRAMMAR.match(value.to_s) && ::Date.parse("#{$1}-01#{$2}")
      super(object, lexical: @string)
    end
  end

  ##
  # gYear represents a gregorian calendar year. The value space of gYear is the set of Gregorian calendar years as
  # defined in § 5.2.1 of [ISO 8601]. Specifically, it is a set of one-year long, non-periodic instances e.g. lexical
  # 1999 to represent the whole year 1999, independent of how many months and days this year has.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#gYear
  class Year < RDF::Literal::Date
    DATATYPE = RDF::XSD.gYear
    GRAMMAR  = %r(\A(-?\d{4,})((?:[\+\-]\d{2}:\d{2})|UTC|Z)?\Z).freeze
    FORMAT   = '%Y'.freeze

    def initialize(value, datatype: nil, lexical: nil, **options)
      @string = lexical || value.to_s
      object = GRAMMAR.match(value.to_s) && ::Date.parse("#{$1}-01-01#{$2}")
      super(object, lexical: @string)
    end
  end

  ##
  # gMonthDay is a gregorian date that recurs, specifically a day of the year such as the third of May. Arbitrary
  # recurring dates are not supported by this datatype. The value space of gMonthDay is the set of calendar dates,
  # as defined in § 3 of [ISO 8601]. Specifically, it is a set of one-day long, annually periodic instances.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#gMonthDay
  class MonthDay < RDF::Literal::Date
    DATATYPE = RDF::XSD.gMonthDay
    GRAMMAR  = %r(\A--(\d{2}-\d{2})((?:[\+\-]\d{2}:\d{2})|UTC|Z)?\Z).freeze
    FORMAT   = '%m-%d'.freeze

    def initialize(value, datatype: nil, lexical: nil, **options)
      @string = lexical || value.to_s
      object = GRAMMAR.match(value.to_s) && ::Date.parse("0000-#{$1}#{$2}")
      super(object, lexical: @string)
    end
  end

  ##
  # gDay is a gregorian day that recurs, specifically a day of the month such as the 5th of the month. Arbitrary
  # recurring days are not supported by this datatype. The value space of gDay is the space of a set of calendar
  # dates as defined in § 3 of [ISO 8601]. Specifically, it is a set of one-day long, monthly periodic instances.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#gDay
  class Day < RDF::Literal::Date
    DATATYPE = RDF::XSD.gDay
    GRAMMAR  = %r(\A---(\d{2})((?:[\+\-]\d{2}:\d{2})|UTC|Z)?\Z).freeze
    FORMAT   = '%d'.freeze

    def initialize(value, datatype: nil, lexical: nil, **options)
      @string = lexical || value.to_s
      object = GRAMMAR.match(value.to_s) && ::Date.parse("0000-01-#{$1}#{$2}")
      super(object, lexical: @string)
    end
  end

  ##
  # gMonth is a gregorian month that recurs every year. The value space of gMonth is the space of a set of calendar
  # months as defined in § 3 of [ISO 8601]. Specifically, it is a set of one-month long, yearly periodic instances.
  #
  # @see https://www.w3.org/TR/2004/REC-xmlschema-2-20041028/#gMonth
  class Month < RDF::Literal::Date
    DATATYPE = RDF::XSD.gMonth
    GRAMMAR  = %r(\A--(\d{2})((?:[\+\-]\d{2}:\d{2})|UTC|Z)?\Z).freeze
    FORMAT   = '%m'.freeze

    def initialize(value, datatype: nil, lexical: nil, **options)
      @string = lexical || value.to_s
      object = GRAMMAR.match(value.to_s) && ::Date.parse("0000-#{$1}-01#{$2}")
      super(object, lexical: @string)
    end
  end
end; end #RDF::Literal