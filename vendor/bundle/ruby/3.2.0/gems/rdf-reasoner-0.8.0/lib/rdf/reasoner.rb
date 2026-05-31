require 'rdf'
require 'rdf/reasoner/extensions'

module RDF
  ##
  # RDFS/OWL reasonsing for RDF.rb.
  #
  # @see https://www.w3.org/TR/2013/REC-sparql11-entailment-20130321/
  # @author [Gregg Kellogg](https://greggkellogg.net/)
  module Reasoner
    require 'rdf/reasoner/format'
    autoload :OWL,     'rdf/reasoner/owl'
    autoload :RDFS,    'rdf/reasoner/rdfs'
    autoload :Schema,  'rdf/reasoner/schema'
    autoload :VERSION, 'rdf/reasoner/version'

    # See https://www.pelagodesign.com/blog/2009/05/20/iso-8601-date-validation-that-doesnt-suck/
    #
    # 
    ISO_8601 =  %r(^
      # Year
      ([\+-]?\d{4}(?!\d{2}\b))
      # Month
      ((-?)((0[1-9]|1[0-2])
            (\3([12]\d|0[1-9]|3[01]))?
          | W([0-4]\d|5[0-2])(-?[1-7])?
          | (00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))
          ([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)
                 ([\.,]\d+(?!:))?)?
                (\17[0-5]\d([\.,]\d+)?)?
                ([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?
          )?
      )?
    $)x.freeze

    ##
    # Add entailment support for the specified regime
    #
    # @param [Array<:owl, :rdfs, :schema>] regime
    def apply(*regime)
      regime.each {|r| require "rdf/reasoner/#{r.to_s.downcase}"}
    end
    module_function :apply

    ##
    # Add all entailment regimes
    def apply_all
      apply(*%w(rdfs owl schema))
    end
    module_function :apply_all

    ##
    # A reasoner error
    class Error < RuntimeError; end
  end
end
