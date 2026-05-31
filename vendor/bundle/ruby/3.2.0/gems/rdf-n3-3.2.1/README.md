# RDF::N3 reader/writer and reasoner
Notation-3 reader/writer for [RDF.rb][RDF.rb] .

[![Gem Version](https://badge.fury.io/rb/rdf-n3.png)](https://badge.fury.io/rb/rdf-n3)
[![Build Status](https://github.com/ruby-rdf/rdf-n3/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/rdf-n3/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/github/ruby-rdf/rdf-n3/badge.svg?branch=develop)](https://coveralls.io/github/ruby-rdf/rdf-n3?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

## Description
RDF::N3 is an Notation-3 parser and reasoner for Ruby using the [RDF.rb][RDF.rb] library suite.

Reader inspired from TimBL predictiveParser and Python librdf implementation.

## Uses CG Specification
This version tracks the [W3C N3 Community Group][] [Specification][N3] which has incompatibilities with the [Team Submission][] version. Notably:

* The `@keywords` declaration is removed, and most form of `@` keywords (e.g., `@is`, `@has`, `@true`) are no longer supported.
* Terminals adhere closely to their counterparts in [Turtle][].
* The modifier `<-` is introduced as a synonym for `is ... of`.
* The SPARQL `BASE` and `PREFIX` declarations are supported.
* Implicit universal variables are defined at the top-level, rather than in the parent formula of the one in which they are defined.
* Support for explicit existential and universal variables (`@forAll` and `@forSome`) has been removed. Quick variables are the standard for universal quantification and blank nodes for existential, but scoping rules are different: Quickvars have top-level scope, and blank nodes formula scope.

This brings N3 closer to compatibility with Turtle.

## Features
RDF::N3 parses [Notation-3][N3], [Turtle][] and [N-Triples][] into statements or quads. It also performs reasoning and serializes to N3.

Install with `gem install rdf-n3`

[Implementation Report](https://ruby-rdf.github.io/rdf-n3/etc/earl.html)

## Limitations
* Support for Variables in Formulae. Existential variables are quantified to RDF::Node instances, Universals to RDF::Query::Variable, with the URI of the variable target used as the variable name.

## Usage
Instantiate a reader from a local file:

    RDF::N3::Reader.open("etc/foaf.n3") do |reader|
       reader.each_statement do |statement|
         puts statement.inspect
       end
    end

Define `@base` and `@prefix` definitions, and use for serialization using `:base_uri` an `:prefixes` options

Write a graph to a file:

    RDF::N3::Writer.open("etc/test.n3") do |writer|
       writer << graph
    end

### Reasoning
Experimental N3 reasoning is supported. Instantiate a reasoner from a dataset:

    RDF::N3::Reasoner.new do |reasoner|
      RDF::N3::Reader.open("etc/foaf.n3") {|reader| reasoner << reader}

       reader.each_statement do |statement|
         puts statement.inspect
       end
    end

Reasoning is performed by turning a repository containing formula and predicate operators into an executable set of operators (similar to the executable SPARQL Algebra). Reasoning adds statements to the base dataset, marked with `:inferred` (e.g. `statement.inferred?`). Predicate operators are defined from the following vocabularies.

When dispatching built-in operators, precedence is given to operators whos operands are fully evaluated, followed by those having only variable output operands, followed by those having the fewest operands. Operators are evaluated until either no solutions are derived, or all operators have been completed.

Reasoning is discussed in the [Design Issues][] document.

#### RDF List vocabulary <http://www.w3.org/2000/10/swap/list#>

  * `list:append` (See {RDF::N3::Algebra::List::Append})
  * `list:first`  (See {RDF::N3::Algebra::List::First})
  * `list:in`     (See {RDF::N3::Algebra::List::In})
  * `list:iterate`     (See {RDF::N3::Algebra::List::Iterate})
  * `list:last`   (See {RDF::N3::Algebra::List::Last})
  * `list:length` (See {RDF::N3::Algebra::List::Length})
  * `list:member` (See {RDF::N3::Algebra::List::Member})

#### RDF Log vocabulary <http://www.w3.org/2000/10/swap/log#>

  * `log:conclusion`    (See {RDF::N3::Algebra::Log::Conclusion})
  * `log:conjunction`   (See {RDF::N3::Algebra::Log::Conjunction})
  * `log:content`       (See {RDF::N3::Algebra::Log::Content})
  * `log:dtlit`       (See {RDF::N3::Algebra::Log::DtLit})
  * `log:equalTo`       (See {RDF::N3::Algebra::Log::EqualTo})
  * `log:implies`       (See {RDF::N3::Algebra::Log::Implies})
  * `log:includes`      (See {RDF::N3::Algebra::Log::Includes})
  * `log:langlit`       (See {RDF::N3::Algebra::Log::LangLit})
  * `log:n3String`      (See {RDF::N3::Algebra::Log::N3String})
  * `log:notEqualTo`    (See {RDF::N3::Algebra::Log::NotEqualTo})
  * `log:notIncludes`   (See {RDF::N3::Algebra::Log::NotIncludes})
  * `log:outputString`  See {RDF::N3::Algebra::Log::OutputString})
  * `log:parsedAsN3`    (See {RDF::N3::Algebra::Log::ParsedAsN3})
  * `log:semantics`     (See {RDF::N3::Algebra::Log::Semantics})

#### RDF Math vocabulary <http://www.w3.org/2000/10/swap/math#>

  * `math:absoluteValue`    (See {RDF::N3::Algebra::Math::AbsoluteValue})
  * `math:acos`             (See {RDF::N3::Algebra::Math::ACos})
  * `math:asin`             (See {RDF::N3::Algebra::Math::ASin})
  * `math:atan`             (See {RDF::N3::Algebra::Math::ATan})
  * `math:acosh`            (See {RDF::N3::Algebra::Math::ACosH})
  * `math:asinh`            (See {RDF::N3::Algebra::Math::ASinH})
  * `math:atanh`            (See {RDF::N3::Algebra::Math::ATanH})
  * `math:ceiling`          (See {RDF::N3::Algebra::Math::Ceiling})
  * `math:cosh`             (See {RDF::N3::Algebra::Math::CosH})
  * `math:cos`              (See {RDF::N3::Algebra::Math::Cos})
  * `math:difference`       (See {RDF::N3::Algebra::Math::Difference})
  * `math:equalTo`          (See {RDF::N3::Algebra::Math::EqualTo})
  * `math:exponentiation`   (See {RDF::N3::Algebra::Math::Exponentiation})
  * `math:floor`            (See {RDF::N3::Algebra::Math::Floor})
  * `math:greaterThan`      (See {RDF::N3::Algebra::Math::GreaterThan})
  * `math:lessThan`         (See {RDF::N3::Algebra::Math::LessThan})
  * `math:negation`         (See {RDF::N3::Algebra::Math::Negation})
  * `math:notEqualTo`       (See {RDF::N3::Algebra::Math::NotEqualTo})
  * `math:notGreaterThan`   (See {RDF::N3::Algebra::Math::NotGreaterThan})
  * `math:notLessThan`      (See {RDF::N3::Algebra::Math::NotLessThan})
  * `math:product`          (See {RDF::N3::Algebra::Math::Product})
  * `math:quotient`         (See {RDF::N3::Algebra::Math::Quotient})
  * `math:remainder`        (See {RDF::N3::Algebra::Math::Remainder})
  * `math:rounded`          (See {RDF::N3::Algebra::Math::Rounded})
  * `math:sinh`             (See {RDF::N3::Algebra::Math::SinH})
  * `math:sin`              (See {RDF::N3::Algebra::Math::Sin})
  * `math:sum`              (See {RDF::N3::Algebra::Math::Sum})
  * `math:tanh`             (See {RDF::N3::Algebra::Math::TanH})
  * `math:tan`              (See {RDF::N3::Algebra::Math::Tan})

#### RDF String vocabulary <http://www.w3.org/2000/10/swap/str#>

  * `string:concatenation`        (See {RDF::N3::Algebra::Str::Concatenation})
  * `string:contains`             (See {RDF::N3::Algebra::Str::Contains})
  * `string:containsIgnoringCase` (See {RDF::N3::Algebra::Str::ContainsIgnoringCase})
  * `string:endsWith`             (See {RDF::N3::Algebra::Str::EndsWith})
  * `string:equalIgnoringCase`    (See {RDF::N3::Algebra::Str::EqualIgnoringCase})
  * `string:format`               (See {RDF::N3::Algebra::Str::Format})
  * `string:greaterThan`          (See {RDF::N3::Algebra::Str::GreaterThan})
  * `string:lessThan`             (See {RDF::N3::Algebra::Str::LessThan})
  * `string:matches`              (See {RDF::N3::Algebra::Str::Matches})
  * `string:notEqualIgnoringCase` (See {RDF::N3::Algebra::Str::NotEqualIgnoringCase})
  * `string:notGreaterThan`       (See {RDF::N3::Algebra::Str::NotGreaterThan})
  * `string:notLessThan`          (See {RDF::N3::Algebra::Str::NotLessThan})
  * `string:notMatches`           (See {RDF::N3::Algebra::Str::NotMatches})
  * `string:replace`              (See {RDF::N3::Algebra::Str::Replace})
  * `string:scrape`               (See {RDF::N3::Algebra::Str::Scrape})
  * `string:startsWith`           (See {RDF::N3::Algebra::Str::StartsWith})

#### RDF Time vocabulary <http://www.w3.org/2000/10/swap/time#>

  * `time:dayOfWeek`              (See {RDF::N3::Algebra::Time::DayOfWeek})
  * `time:day`                    (See {RDF::N3::Algebra::Time::Day})
  * `time:gmTime`                 (See {RDF::N3::Algebra::Time::GmTime})
  * `time:hour`                   (See {RDF::N3::Algebra::Time::Hour})
  * `time:inSeconds`              (See {RDF::N3::Algebra::Time::InSeconds})
  * `time:localTime`              (See {RDF::N3::Algebra::Time::LocalTime})
  * `time:minute`                 (See {RDF::N3::Algebra::Time::Minute})
  * `time:month`                  (See {RDF::N3::Algebra::Time::Month})
  * `time:second`                 (See {RDF::N3::Algebra::Time::Second})
  * `time:timeZone`               (See {RDF::N3::Algebra::Time::Timezone})
  * `time:year`                   (See {RDF::N3::Algebra::Time::Year})

### Formulae / Quoted Graphs

N3 Formulae are introduced with the `{ statement-list }` syntax. A given formula is assigned an `RDF::Node` instance, which is also used as the graph_name for `RDF::Statement` instances provided to `RDF::N3::Reader#each_statement`. For example, the following N3 generates the associated statements:

    @prefix x: <http://example.org/x-ns/#> .
    @prefix log: <http://www.w3.org/2000/10/swap/log#> .
    @prefix dc: <http://purl.org/dc/elements/1.1/#> .

    { [ x:firstname  "Ora" ] dc:wrote [ dc:title  "Moby Dick" ] } a log:falsehood .
  
when turned into an RDF Repository results in the following quads

    _:form <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2000/10/swap/log#falsehood> .
    _:moby <http://purl.org/dc/elements/1.1/#title> "Moby Dick" _:form .
    _:ora <http://purl.org/dc/elements/1.1/#wrote> _:moby _:form .
    _:ora <http://example.org/x-ns/#firstname> "Ora" _:form .

Reasoning uses a Notation3 Algebra, similar to [SPARQL S-Expressions][]. This implementation considers formulae to be patterns, which may be asserted on statements made in the default graph, possibly loaded from a separate file. The logical relationships are reduced to algebraic operators. 

### Variables
The latest version of N3 supports only quickVars (e.g., `?x`). THe former explicit `@forAll` and `@forSome` of been removed.
Existential variables are replaced with an allocated `RDF::Node` instance.

Note that the behavior of both existential and universal variables is not entirely in keeping with the [Team Submission][], and neither work quite like SPARQL variables. When used in the antecedent part of an implication, universal variables should behave much like SPARQL variables. This area is subject to a fair amount of change.

* Variables, themselves, cannot be part of a solution, which limits the ability to generate updated rules for reasoning.
* Both Existentials and Universals are treated as simple variables, and there is really no preference given based on the order in which they are introduced.

### Query
Formulae are typically used to query the knowledge-base, which is set from the base-formula/default graph. A formula is composed of both constant statements, and variable statements. When running as a query, such as for the antecedent formula in `log:implies`, statements including either explicit variables or blank nodes are treated as query patterns and are used to query the knowledge base to create a solution set, which is used either prove the formula correct, or create bindings passed to the consequent formula.

Blank nodes associated with rdf:List statements used as part of a built-in are made _non-distinguished_ existential variables, and patters containing these variables become optional. If they are not bound as part of the query, the implicitly are bound as the original blank nodes defined within the formula, which allows for both constant list arguments, list arguments that contain variables, or arguments which are variables expanding to lists.

## Dependencies
* [Ruby](https://ruby-lang.org/) (>= 2.6)
* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.2)
* [EBNF][EBNF gem] (~> 2.2)
* [SPARQL][SPARQL gem] (~> 3.1)
* [SXP][SXP gem] (~> 1.2)

## Documentation
Full documentation available on [RubyDoc.info](https://ruby-rdf.github.io/rdf-n3)

### Principle Classes
* {RDF::N3}
* {RDF::N3::Format}
* {RDF::N3::Reader}
* {RDF::N3::Reasoner}
* {RDF::N3::Writer}
* {RDF::N3::Algebra}
  * {RDF::N3::Algebra::Formula}

### Additional vocabularies
* {RDF::N3::Rei}
* {RDF::N3::Crypto}
* {RDF::N3::Math}
* {RDF::N3::Time}

## Resources
* [RDF.rb][RDF.rb]
* [Distiller](http://rdf.greggkellogg.net/distiller)
* [Documentation](https://ruby-rdf.github.io/rdf-n3/)
* [History](file:file.History.html)
* [Notation-3][N3]
* [Team Submission][]
* [N3 Primer](https://www.w3.org/2000/10/swap/Primer.html)
* [N3 Reification](https://www.w3.org/DesignIssues/Reify.html)
* [Turtle][]
* [W3C SWAP Test suite](https://w3c.github.io/N3/tests/)
* [W3C Turtle Test suite](https://w3c.github.io/rdf-tests/turtle/)
* [N-Triples][]

## Author
* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

## Contributing
This repository uses [Git Flow](https://github.com/nvie/gitflow) to mange development and release activity. All submissions _must_ be on a feature branch based on the _develop_ branch to ease staging and integration.

* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
* Do document every method you add using [YARD][] annotations. Read the
  [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the `.gemspec`, `VERSION` or `AUTHORS` files. If you need to
  change them, do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the corresponding
  list in the the `README`. Alphabetical order applies.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you,
  which you will be asked to agree to on the first commit to a repo within the organization.
  Note that the agreement applies to all repos in the [Ruby RDF](https://github.com/ruby-rdf/) organization.

## License

This is free and unencumbered public domain software. For more information,
see <https://unlicense.org/> or the accompanying {file:UNLICENSE} file.

## Feedback
* <gregg@greggkellogg.net>
* <https://rubygems.org/gem/rdf-n3>
* <https://github.com/ruby-rdf/rdf-n3>
* <https://lists.w3.org/Archives/Public/public-rdf-ruby/>

[RDF::Turtle]:            https://ruby-rdf.github.io/rdf-turtle/
[Design Issues]:        https://www.w3.org/DesignIssues/Notation3.html "Notation-3 Design Issues"
[Team Submission]:  https://www.w3.org/TeamSubmission/n3/
[Turtle]:                     https://www.w3.org/TR/turtle/
[N-Triples]:               https://www.w3.org/TR/n-triples/
[YARD]:                   https://yardoc.org/
[YARD-GS]:            https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:                    https://unlicense.org/#unlicensing-contributions
[SPARQL S-Expressions]: https://jena.apache.org/documentation/notes/sse.html
[W3C N3 Community Group]: https://www.w3.org/community/n3-dev/
[N3]:                       https://w3c.github.io/N3/spec/
[PEG]:                    https://en.wikipedia.org/wiki/Parsing_expression_grammar
[RDF.rb]:                https://ruby-rdf.github.io/rdf
[EBNF gem]:         https://ruby-rdf.github.io/ebnf
[SPARQL gem]:     https://ruby-rdf.github.io/sparql
[SXP gem]:            https://ruby-rdf.github.io/sxp
