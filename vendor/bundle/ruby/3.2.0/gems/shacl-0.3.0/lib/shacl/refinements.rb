# Localized refinements to externally defined classes
module SHACL::Refinements
  using SHACL::Refinements

  refine Hash do
    # @!parse
    #   # Refinements on Hash
    #   class Hash
    #     ##
    #     # Deep merge two hashes folding array values together.
    #     #
    #     # @param  [Hash] second
    #     # @return [Hash]
    #     def deep_merge(second); end
    #   end
    def deep_merge(second)
      merger = ->(_, v1, v2) {Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : v2.nil? ? v1 : v2 }
      merge(second.to_h, &merger)
    end
  end

  refine SPARQL::Algebra::Operator::Alt do
    # @!parse
    #   # Refinements on SPARQL::Algebra::Operator::Alt
    #   class SPARQL::Algebra::Operator::Alt
    #     ##
    #     # Retrieve the possibly newly assigned blank node subject to use for representing this operator.
    #     # @return [RDF::Node]
    #     attr_accessor :subject
    #
    #     ##
    #     # Generate the SHACL representation of this operator
    #     # @return [RDF::Node]
    #     def each_statement(&block); end.
    #   end
    attr_accessor :subject
    def each_statement(&block)
      @subject = RDF::Node.new
      elements = operands.map do |op|
        if op.respond_to?(:each_statement)
          op.each_statement(&block)
          op.subject
        else
          op
        end
      end
      list = RDF::List(*elements)
      list.each_statement(&block)
      block.call(RDF::Statement(@subject, RDF::Vocab::SHACL.alternativePath, list.subject))
    end
  end

  refine SPARQL::Algebra::Operator::PathOpt do
    # @!parse
    #   # Refinements on SPARQL::Algebra::Operator::PathOpt
    #   class SPARQL::Algebra::Operator::Alt
    #     ##
    #     # Retrieve the possibly newly assigned blank node subject to use for representing this operator.
    #     # @return [RDF::Node]
    #     attr_accessor :subject
    #
    #     ##
    #     # Generate the SHACL representation of this operator
    #     # @return [RDF::Node]
    #     def each_statement(&block); end.
    #   end
    attr_accessor :subject
    def each_statement(&block)
      @subject = RDF::Node.new
      operands.each do |op|
        obj = if op.respond_to?(:each_statement)
          op.each_statement(&block)
          op.subject
        else
          op
        end
        block.call(RDF::Statement(@subject, RDF::Vocab::SHACL.zeroOrOnePath, obj))
      end
    end
  end

  refine SPARQL::Algebra::Operator::PathPlus do
    # @!parse
    #   # Refinements on SPARQL::Algebra::Operator::PathPlus
    #   class SPARQL::Algebra::Operator::Alt
    #     ##
    #     # Retrieve the possibly newly assigned blank node subject to use for representing this operator.
    #     # @return [RDF::Node]
    #     attr_accessor :subject
    #
    #     ##
    #     # Generate the SHACL representation of this operator
    #     # @return [RDF::Node]
    #     def each_statement(&block); end.
    #   end
    attr_accessor :subject
    def each_statement(&block)
      @subject = RDF::Node.new
      operands.each do |op|
        obj = if op.respond_to?(:each_statement)
          op.each_statement(&block)
          op.subject
        else
          op
        end
        block.call(RDF::Statement(@subject, RDF::Vocab::SHACL.oneOrMorePath, obj))
      end
    end
  end

  refine SPARQL::Algebra::Operator::PathStar do
    # @!parse
    #   # Refinements on SPARQL::Algebra::Operator::PathPlus
    #   class SPARQL::Algebra::Operator::Alt
    #     ##
    #     # Retrieve the possibly newly assigned blank node subject to use for representing this operator.
    #     # @return [RDF::Node]
    #     attr_accessor :subject
    #
    #     ##
    #     # Generate the SHACL representation of this operator
    #     # @return [RDF::Node]
    #     def each_statement(&block); end.
    #   end
    attr_accessor :subject
    def each_statement(&block)
      @subject = RDF::Node.new
      operands.each do |op|
        obj = if op.respond_to?(:each_statement)
          op.each_statement(&block)
          op.subject
        else
          op
        end
        block.call(RDF::Statement(@subject, RDF::Vocab::SHACL.zeroOrMorePath, obj))
      end
    end
  end

  refine SPARQL::Algebra::Operator::Reverse do
    # @!parse
    #   # Refinements on SPARQL::Algebra::Operator::Reverse
    #   class SPARQL::Algebra::Operator::Alt
    #     ##
    #     # Retrieve the possibly newly assigned blank node subject to use for representing this operator.
    #     # @return [RDF::Node]
    #     attr_accessor :subject
    #
    #     ##
    #     # Generate the SHACL representation of this operator
    #     # @return [RDF::Node]
    #     def each_statement(&block); end.
    #   end
    attr_accessor :subject
    def each_statement(&block)
      @subject = RDF::Node.new
      operands.each do |op|
        obj = if op.respond_to?(:each_statement)
          op.each_statement(&block)
          op.subject
        else
          op
        end
        block.call(RDF::Statement(@subject, RDF::Vocab::SHACL.inversePath, obj))
      end
    end
  end

  refine SPARQL::Algebra::Operator::Seq do
    # @!parse
    #   # Refinements on SPARQL::Algebra::Operator::Seq
    #   class SPARQL::Algebra::Operator::Alt
    #     ##
    #     # Retrieve the possibly newly assigned blank node subject to use for representing this operator.
    #     # @return [RDF::Node]
    #     attr_accessor :subject
    #
    #     ##
    #     # Generate the SHACL representation of this operator
    #     # @return [RDF::Node]
    #     def each_statement(&block); end.
    #   end
    attr_accessor :subject
    def each_statement(&block)
      elements = operands.map do |op|
        if op.respond_to?(:each_statement)
          op.each_statement(&block)
          op.subject
        else
          op
        end
      end
      list = RDF::List(*elements)
      list.each_statement(&block)
      @subject = list.subject
    end
  end
end