$:.unshift(File.expand_path("../..", __FILE__))

require 'rdf'
require 'sxp'
require_relative 'refinements'
require_relative 'validation_report'

module SHACL
  # A SHACL [Validateion Report](https://www.w3.org/TR/shacl/#results-validation-report).
  #
  # Collects the individual {SHACL::ValidationResult} instances and provides a `conforms` boolean accessor.
  #
  # Allows the report to be serialized as a set of RDF Statements
  class ValidationReport
    include RDF::Enumerable
    using SHACL::Refinements

    ##
    # All results, both conforming and non-conforming
    attr_reader :all_results

    ##
    # Creates a report from the set of results
    #
    # @param [Array<ValidationResult>] results
    # @return [ValidationReport]
    def initialize(results)
      @all_results = Array(results)
    end

    ##
    # The non-conforming results
    #
    # @return [Array<ValidationResult>]
    def results
      @all_results.reject(&:conform?)
    end

    ##
    # The number of non-conforming results
    #
    # @return [Integer]
    def count
      results.length
    end

    ##
    # Do the individual results indicate conformance?
    #
    # @return [Boolean]
    def conform?
      results.empty?
    end

    ##
    # The number of results
    #
    def to_sxp_bin
      [:ValidationReport, conform?, results].to_sxp_bin
    end

    ##
    # Transform Report to SXP
    #
    # @return [String]
    def to_sxp(**options)
      self.to_sxp_bin.to_sxp(**options)
    end

    def to_s
      results.map(&:to_s).join("\n")
    end

    ##
    # Two reports are eq if they have the same number of results and each result equals a result in the other report.
    # @param [ValidationReport] other
    # @return [Boolean]
    def ==(other)
      return false unless other.is_a?(ValidationReport)
      count == other.count && other.results.all? {|r| results.include?(r)}
    end

    ##
    # Create a hash of messages appropriate for linter-like output.
    #
    # @return [Hash{Symbol => Hash{Symbol => Array<String>}}]
    def linter_messages
      results.inject({}) {|memo, result| memo.deep_merge(result.linter_message)}
    end

    ##
    # Yields statements for this report
    #
    # @yield  [statement]
    #   each statement
    # @yieldparam  [RDF::Statement] statement
    # @yieldreturn [void] ignored
    # @return [void]
    def each(&block)
      subject = RDF::Node.new
      block.call(RDF::Statement(subject, RDF.type, RDF::Vocab::SHACL.ValidationReport))
      block.call(RDF::Statement(subject, RDF::Vocab::SHACL.conforms, RDF::Literal(conform?)))
      results.each do |result|
        result_subject = nil
        result.each do |statement|
          result_subject ||= statement.subject
          yield(statement)
        end
        yield(RDF::Statement(subject, RDF::Vocab::SHACL.result, result_subject))
      end
    end
  end
end
