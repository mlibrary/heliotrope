$:.unshift(File.expand_path("../..", __FILE__))
require 'sparql/algebra'
require 'sxp'

module RDF::N3
  # Based on the SPARQL Algebra, operators for executing a patch
  #
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  module Algebra
    autoload :Builtin,                'rdf/n3/algebra/builtin'
    autoload :Formula,                'rdf/n3/algebra/formula'
    autoload :ListOperator,           'rdf/n3/algebra/list_operator'
    autoload :NotImplemented,         'rdf/n3/algebra/not_implemented'
    autoload :ResourceOperator,       'rdf/n3/algebra/resource_operator'

    module List
      def vocab; RDF::N3::List.to_uri; end
      module_function :vocab
      autoload :Append,               'rdf/n3/algebra/list/append'
      autoload :First,                'rdf/n3/algebra/list/first'
      autoload :In,                   'rdf/n3/algebra/list/in'
      autoload :Iterate,              'rdf/n3/algebra/list/iterate'
      autoload :Last,                 'rdf/n3/algebra/list/last'
      autoload :Length,               'rdf/n3/algebra/list/length'
      autoload :Member,               'rdf/n3/algebra/list/member'
    end

    module Log
      def vocab; RDF::N3::Log.to_uri; end
      module_function :vocab
      autoload :Conclusion,           'rdf/n3/algebra/log/conclusion'
      autoload :Conjunction,          'rdf/n3/algebra/log/conjunction'
      autoload :Content,              'rdf/n3/algebra/log/content'
      autoload :DtLit,                'rdf/n3/algebra/log/dtlit'
      autoload :EqualTo,              'rdf/n3/algebra/log/equal_to'
      autoload :Implies,              'rdf/n3/algebra/log/implies'
      autoload :Includes,             'rdf/n3/algebra/log/includes'
      autoload :LangLit,              'rdf/n3/algebra/log/langlit'
      autoload :N3String,             'rdf/n3/algebra/log/n3_string'
      autoload :NotEqualTo,           'rdf/n3/algebra/log/not_equal_to'
      autoload :NotIncludes,          'rdf/n3/algebra/log/not_includes'
      autoload :OutputString,         'rdf/n3/algebra/log/output_string'
      autoload :ParsedAsN3,           'rdf/n3/algebra/log/parsed_as_n3'
      autoload :Semantics,            'rdf/n3/algebra/log/semantics'
    end

    module Math
      def vocab; RDF::N3::Math.to_uri; end
      module_function :vocab
      autoload :AbsoluteValue,        'rdf/n3/algebra/math/absolute_value'
      autoload :ACos,                 'rdf/n3/algebra/math/acos'
      autoload :ASin,                 'rdf/n3/algebra/math/asin'
      autoload :ATan,                 'rdf/n3/algebra/math/atan'
      autoload :ACosH,                'rdf/n3/algebra/math/acosh'
      autoload :ASinH,                'rdf/n3/algebra/math/asinh'
      autoload :ATanH,                'rdf/n3/algebra/math/atanh'
      autoload :Ceiling,              'rdf/n3/algebra/math/ceiling'
      autoload :Cos,                  'rdf/n3/algebra/math/cos'
      autoload :CosH,                 'rdf/n3/algebra/math/cosh'
      autoload :Difference,           'rdf/n3/algebra/math/difference'
      autoload :EqualTo,              'rdf/n3/algebra/math/equal_to'
      autoload :Exponentiation,       'rdf/n3/algebra/math/exponentiation'
      autoload :Floor,                'rdf/n3/algebra/math/floor'
      autoload :GreaterThan,          'rdf/n3/algebra/math/greater_than'
      autoload :LessThan,             'rdf/n3/algebra/math/less_than'
      autoload :Negation,             'rdf/n3/algebra/math/negation'
      autoload :NotEqualTo,           'rdf/n3/algebra/math/not_equal_to'
      autoload :NotGreaterThan,       'rdf/n3/algebra/math/not_greater_than'
      autoload :NotLessThan,          'rdf/n3/algebra/math/not_less_than'
      autoload :Product,              'rdf/n3/algebra/math/product'
      autoload :Quotient,             'rdf/n3/algebra/math/quotient'
      autoload :Remainder,            'rdf/n3/algebra/math/remainder'
      autoload :Rounded,              'rdf/n3/algebra/math/rounded'
      autoload :Sin,                  'rdf/n3/algebra/math/sin'
      autoload :SinH,                 'rdf/n3/algebra/math/sinh'
      autoload :Sum,                  'rdf/n3/algebra/math/sum'
      autoload :Tan,                  'rdf/n3/algebra/math/tan'
      autoload :TanH,                 'rdf/n3/algebra/math/tanh'
    end

    module Str
      def vocab; RDF::N3::Str.to_uri; end
      module_function :vocab
      autoload :Concatenation,        'rdf/n3/algebra/str/concatenation'
      autoload :Contains,             'rdf/n3/algebra/str/contains'
      autoload :ContainsIgnoringCase, 'rdf/n3/algebra/str/contains_ignoring_case'
      autoload :EndsWith,             'rdf/n3/algebra/str/ends_with'
      autoload :EqualIgnoringCase,    'rdf/n3/algebra/str/equal_ignoring_case'
      autoload :Format,               'rdf/n3/algebra/str/format'
      autoload :GreaterThan,          'rdf/n3/algebra/str/greater_than'
      autoload :LessThan,             'rdf/n3/algebra/str/less_than'
      autoload :Matches,              'rdf/n3/algebra/str/matches'
      autoload :NotEqualIgnoringCase, 'rdf/n3/algebra/str/not_equal_ignoring_case'
      autoload :NotGreaterThan,       'rdf/n3/algebra/str/not_greater_than'
      autoload :NotLessThan,          'rdf/n3/algebra/str/not_less_than'
      autoload :NotMatches,           'rdf/n3/algebra/str/not_matches'
      autoload :Replace,              'rdf/n3/algebra/str/replace'
      autoload :Scrape,               'rdf/n3/algebra/str/scrape'
      autoload :StartsWith,           'rdf/n3/algebra/str/starts_with'
    end

    module Time
      def vocab; RDF::N3::Time.to_uri; end
      module_function :vocab
      autoload :DayOfWeek,            'rdf/n3/algebra/time/day_of_week'
      autoload :Day,                  'rdf/n3/algebra/time/day'
      autoload :GmTime,               'rdf/n3/algebra/time/gm_time'
      autoload :Hour,                 'rdf/n3/algebra/time/hour'
      autoload :InSeconds,            'rdf/n3/algebra/time/in_seconds'
      autoload :LocalTime,            'rdf/n3/algebra/time/local_time'
      autoload :Minute,               'rdf/n3/algebra/time/minute'
      autoload :Month,                'rdf/n3/algebra/time/month'
      autoload :Second,               'rdf/n3/algebra/time/second'
      autoload :Timezone,             'rdf/n3/algebra/time/timezone'
      autoload :Year,                 'rdf/n3/algebra/time/year'
    end

    def for(uri)
      {
        RDF::N3::List.append              => List.const_get(:Append),
        RDF::N3::List.first               => List.const_get(:First),
        RDF::N3::List.in                  => List.const_get(:In),
        RDF::N3::List.iterate             => List.const_get(:Iterate),
        RDF::N3::List.last                => List.const_get(:Last),
        RDF::N3::List.length              => List.const_get(:Length),
        RDF::N3::List.member              => List.const_get(:Member),

        RDF::N3::Log.conclusion           => Log.const_get(:Conclusion),
        RDF::N3::Log.conjunction          => Log.const_get(:Conjunction),
        RDF::N3::Log.content              => Log.const_get(:Content),
        RDF::N3::Log.dtlit                => Log.const_get(:DtLit),
        RDF::N3::Log.equalTo              => Log.const_get(:EqualTo),
        RDF::N3::Log.implies              => Log.const_get(:Implies),
        RDF::N3::Log.includes             => Log.const_get(:Includes),
        RDF::N3::Log.langlit              => Log.const_get(:LangLit),
        RDF::N3::Log.n3String             => Log.const_get(:N3String),
        RDF::N3::Log.notEqualTo           => Log.const_get(:NotEqualTo),
        RDF::N3::Log.notIncludes          => Log.const_get(:NotIncludes),
        RDF::N3::Log.outputString         => Log.const_get(:OutputString),
        RDF::N3::Log.parsedAsN3           => Log.const_get(:ParsedAsN3),
        RDF::N3::Log.semantics            => Log.const_get(:Semantics),
        RDF::N3::Log.supports             => NotImplemented,

        RDF::N3::Math.absoluteValue       => Math.const_get(:AbsoluteValue),
        RDF::N3::Math.acos                => Math.const_get(:ACos),
        RDF::N3::Math.asin                => Math.const_get(:ASin),
        RDF::N3::Math.atan                => Math.const_get(:ATan),
        RDF::N3::Math.acosh               => Math.const_get(:ACosH),
        RDF::N3::Math.asinh               => Math.const_get(:ASinH),
        RDF::N3::Math.atanh               => Math.const_get(:ATanH),
        RDF::N3::Math.ceiling             => Math.const_get(:Ceiling),
        RDF::N3::Math.ceiling             => Math.const_get(:Ceiling),
        RDF::N3::Math.cos                 => Math.const_get(:Cos),
        RDF::N3::Math.cosh                => Math.const_get(:CosH),
        RDF::N3::Math.difference          => Math.const_get(:Difference),
        RDF::N3::Math.equalTo             => Math.const_get(:EqualTo),
        RDF::N3::Math.exponentiation      => Math.const_get(:Exponentiation),
        RDF::N3::Math.floor               => Math.const_get(:Floor),
        RDF::N3::Math.greaterThan         => Math.const_get(:GreaterThan),
        RDF::N3::Math.lessThan            => Math.const_get(:LessThan),
        RDF::N3::Math.negation            => Math.const_get(:Negation),
        RDF::N3::Math.notEqualTo          => Math.const_get(:NotEqualTo),
        RDF::N3::Math.notGreaterThan      => Math.const_get(:NotGreaterThan),
        RDF::N3::Math.notLessThan         => Math.const_get(:NotLessThan),
        RDF::N3::Math.product             => Math.const_get(:Product),
        RDF::N3::Math.quotient            => Math.const_get(:Quotient),
        RDF::N3::Math.remainder           => Math.const_get(:Remainder),
        RDF::N3::Math.rounded             => Math.const_get(:Rounded),
        RDF::N3::Math.sin                 => Math.const_get(:Sin),
        RDF::N3::Math.sinh                => Math.const_get(:SinH),
        RDF::N3::Math.tan                 => Math.const_get(:Tan),
        RDF::N3::Math.tanh                => Math.const_get(:TanH),
        RDF::N3::Math[:sum]               => Math.const_get(:Sum),

        RDF::N3::Str.concatenation        => Str.const_get(:Concatenation),
        RDF::N3::Str.contains             => Str.const_get(:Contains),
        RDF::N3::Str.containsIgnoringCase => Str.const_get(:ContainsIgnoringCase),
        RDF::N3::Str.containsRoughly      => NotImplemented,
        RDF::N3::Str.endsWith             => Str.const_get(:EndsWith),
        RDF::N3::Str.equalIgnoringCase    => Str.const_get(:EqualIgnoringCase),
        RDF::N3::Str.format               => Str.const_get(:Format),
        RDF::N3::Str.greaterThan          => Str.const_get(:GreaterThan),
        RDF::N3::Str.lessThan             => Str.const_get(:LessThan),
        RDF::N3::Str.matches              => Str.const_get(:Matches),
        RDF::N3::Str.notEqualIgnoringCase => Str.const_get(:NotEqualIgnoringCase),
        RDF::N3::Str.notGreaterThan       => Str.const_get(:NotGreaterThan),
        RDF::N3::Str.notLessThan          => Str.const_get(:NotLessThan),
        RDF::N3::Str.notMatches           => Str.const_get(:NotMatches),
        RDF::N3::Str.replace              => Str.const_get(:Replace),
        RDF::N3::Str.scrape               => Str.const_get(:Scrape),
        RDF::N3::Str.startsWith           => Str.const_get(:StartsWith),

        RDF::N3::Time.dayOfWeek           => Time.const_get(:DayOfWeek),
        RDF::N3::Time.day                 => Time.const_get(:Day),
        RDF::N3::Time.gmTime              => Time.const_get(:GmTime),
        RDF::N3::Time.hour                => Time.const_get(:Hour),
        RDF::N3::Time.inSeconds           => Time.const_get(:InSeconds),
        RDF::N3::Time.localTime           => Time.const_get(:LocalTime),
        RDF::N3::Time.minute              => Time.const_get(:Minute),
        RDF::N3::Time.month               => Time.const_get(:Month),
        RDF::N3::Time.second              => Time.const_get(:Second),
        RDF::N3::Time.timeZone            => Time.const_get(:Timezone),
        RDF::N3::Time.year                => Time.const_get(:Year),
      }[uri]
    end
    module_function :for
  end
end


