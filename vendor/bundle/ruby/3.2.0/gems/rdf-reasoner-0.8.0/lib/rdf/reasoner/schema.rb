# coding: utf-8

# Also requires RDFS reasoner
require 'rdf/reasoner/rdfs'

module RDF::Reasoner
  ##
  # Rules for generating RDFS entailment triples
  #
  # Extends `RDF::URI` with specific entailment capabilities
  module Schema

    ##
    # Schema.org requires that if the property has a domain, and the resource has a type that some type matches some domain.
    #
    # Note that this is different than standard entailment, which simply asserts that the resource has every type in the domain, but this is more useful to check if published data is consistent with the vocabulary definition.
    #
    # If `resource` is of type `schema:Role`, `resource` is domain acceptable if any other resource references `resource` using this property.
    #
    # @param [RDF::Resource] resource
    # @param [RDF::Queryable] queryable
    # @param [Hash{Symbol => Object}] options
    # @option options [Array<RDF::Vocabulary::Term>] :types
    #   Fully entailed types of resource, if not provided, they are queried
    def domain_compatible_schema?(resource, queryable, options = {})
      raise RDF::Reasoner::Error, "#{self} can't get domains" unless property?
      domains = Array(self.domainIncludes) +
                Array(self.properties[:'https://schema.org/domainIncludes']) -
                [RDF::OWL.Thing]

      # Fully entailed types of the resource
      types = entailed_types(resource, queryable, **options) unless domains.empty?

      # Every domain must match some entailed type
      resource_acceptable = Array(types).empty? || domains.any? {|d| types.include?(d)}

      # Resource may still be acceptable if types include schema:Role, and any any other resource references `resource` using this property
      resource_acceptable ||
        (types.include?(RDF::URI("http://schema.org/Role")) || types.include?(RDF::URI("https://schema.org/Role"))) &&
        !queryable.query({predicate: self, object: resource}).empty?
    end

    ##
    # Schema.org requires that if the property has a range, and the resource has a type that some type matches some range. If the resource is a datatyped Literal, and the range includes a datatype, the resource must be consistent with that.
    #
    # If `resource` is of type `schema:Role`, it is range acceptable if it has the same property with an acceptable value.
    #
    # If `resource` is of type `rdf:List` (must be previously entailed), it is range acceptable if all members of the list are otherwise range acceptable on the same property.
    #
    # Also, a plain literal (or schema:Text) is always compatible with an object range.
    #
    # @param [RDF::Resource] resource
    # @param [RDF::Queryable] queryable
    # @param [Hash{Symbol => Object}] options ({})
    # @option options [Array<RDF::Vocabulary::Term>] :types
    #   Fully entailed types of resource, if not provided, they are queried
    def range_compatible_schema?(resource, queryable, options = {})
      raise RDF::Reasoner::Error, "#{self} can't get ranges" unless property?
      if !(ranges = Array(self.rangeIncludes) +
                    Array(self.properties[:'https://schema.org/rangeIncludes']) -
                    [RDF::OWL.Thing]).empty?
        if resource.literal?
          ranges.any? do |range|
            case range
            when RDF::RDFS.Literal  then true
            when RDF::URI("http://schema.org/Text"), RDF::URI("https://schema.org/Text")
              resource.plain? || resource.datatype == RDF::URI("http://schema.org/Text")
            when RDF::URI("http://schema.org/Boolean"), RDF::URI("https://schema.org/Boolean")
              [
                RDF::URI("http://schema.org/Boolean"),
                RDF::URI("https://schema.org/Boolean"),
                RDF::XSD.boolean
              ].include?(resource.datatype) ||
              resource.plain? && RDF::Literal::Boolean.new(resource.value).valid?
            when RDF::URI("http://schema.org/Date"), RDF::URI("https://schema.org/Date")
              # Schema.org date based on ISO 8601, mapped to appropriate XSD types for validation
              case resource
              when RDF::Literal::Date, RDF::Literal::Time, RDF::Literal::DateTime, RDF::Literal::Duration
                resource.valid?
              else
                ISO_8601.match(resource.value)
              end
            when RDF::URI("http://schema.org/DateTime"), RDF::URI("https://schema.org/DateTime")
              resource.datatype == RDF::URI("http://schema.org/DateTime") ||
              resource.datatype == RDF::URI("https://schema.org/DateTime") ||
              resource.is_a?(RDF::Literal::DateTime) ||
              resource.plain? && RDF::Literal::DateTime.new(resource.value).valid?
            when RDF::URI("http://schema.org/Duration"), RDF::URI("https://schema.org/Duration")
              value = resource.value
              value = "P#{value}" unless value.start_with?("P")
              resource.datatype == RDF::URI("http://schema.org/Duration") ||
              resource.datatype == RDF::URI("https://schema.org/Duration") ||
              resource.is_a?(RDF::Literal::Duration) ||
              resource.plain? && RDF::Literal::Duration.new(value).valid?
            when RDF::URI("http://schema.org/Time"), RDF::URI("https://schema.org/Time")
              resource.datatype == RDF::URI("http://schema.org/Time") ||
              resource.datatype == RDF::URI("https://schema.org/Time") ||
              resource.is_a?(RDF::Literal::Time) ||
              resource.plain? && RDF::Literal::Time.new(resource.value).valid?
            when RDF::URI("http://schema.org/Number"), RDF::URI("https://schema.org/Number")
              resource.is_a?(RDF::Literal::Numeric) ||
              [
                RDF::URI("http://schema.org/Number"),
                RDF::URI("http://schema.org/Float"),
                RDF::URI("http://schema.org/Integer"),
                RDF::URI("https://schema.org/Number"),
                RDF::URI("https://schema.org/Float"),
                RDF::URI("https://schema.org/Integer"),
              ].include?(resource.datatype) ||
              resource.plain? && RDF::Literal::Integer.new(resource.value).valid? ||
              resource.plain? && RDF::Literal::Double.new(resource.value).valid?
            when RDF::URI("http://schema.org/Float"), RDF::URI("https://schema.org/Float")
              resource.is_a?(RDF::Literal::Double) ||
              [
                RDF::URI("http://schema.org/Number"),
                RDF::URI("http://schema.org/Float"),
                RDF::URI("https://schema.org/Number"),
                RDF::URI("https://schema.org/Float"),
              ].include?(resource.datatype) ||
              resource.plain? && RDF::Literal::Double.new(resource.value).valid?
            when RDF::URI("http://schema.org/Integer"), RDF::URI("https://schema.org/Integer")
              resource.is_a?(RDF::Literal::Integer) ||
              [
                RDF::URI("http://schema.org/Number"),
                RDF::URI("http://schema.org/Integer"),
                RDF::URI("https://schema.org/Number"),
                RDF::URI("https://schema.org/Integer"),
              ].include?(resource.datatype) ||
              resource.plain? && RDF::Literal::Integer.new(resource.value).valid?
            when RDF::URI("http://schema.org/URL"), RDF::URI("https://schema.org/URL")
              resource.datatype == RDF::URI("http://schema.org/URL") ||
              resource.datatype == RDF::URI("https://schema.org/URL") ||
              resource.datatype == RDF::XSD.anyURI ||
              resource.plain? && RDF::Literal::AnyURI.new(resource.value).valid?
            else
              # If may be an XSD range, look for appropriate literal
              if range.start_with?(RDF::XSD.to_s)
                if resource.datatype == RDF::URI(range)
                  true
                else
                  # Valid if cast as datatype
                  resource.plain? && RDF::Literal(resource.value, datatype: RDF::URI(range)).valid?
                end
              else
                # Otherwise, presume that the range refers to a typed resource. This is allowed if the value is a plain literal
                resource.plain?
              end
            end
          end
        elsif %w(
            http://schema.org/True
            http://schema.org/False
            https://schema.org/True
            https://schema.org/False
          ).include?(resource) &&
          (ranges.include?(RDF::URI("http://schema.org/Boolean")) || ranges.include?(RDF::URI("https://schema.org/Boolean")))
          true # Special case for schema boolean resources
        elsif (ranges.include?(RDF::URI("http://schema.org/URL")) || ranges.include?(RDF::URI("https://schema.org/URL"))) &&
              resource.uri?
          true # schema:URL matches URI resources
        elsif ranges == [RDF::URI("http://schema.org/Text")] && resource.uri?
          # Allowed if resource is untyped
          entailed_types(resource, queryable, **options).empty?
        elsif ranges == [RDF::URI("https://schema.org/Text")] && resource.uri?
          # Allowed if resource is untyped
          entailed_types(resource, queryable, **options).empty?
        elsif literal_range?(ranges)
          false # If resource isn't literal, this is a range violation
        else
          # Fully entailed types of the resource
          types = entailed_types(resource, queryable, **options)

          # Every range must match some entailed type
          resource_acceptable = Array(types).empty? || ranges.any? {|d| types.include?(d)}

          # Resource may still be acceptable if it has the same property with an acceptable value
          resource_acceptable ||

          # Resource also acceptable if it is a Role, and the Role object contains the same predicate having a compatible object
          (types.include?(RDF::URI("http://schema.org/Role")) || types.include?(RDF::URI("https://schema.org/Role"))) &&
            queryable.query({subject: resource, predicate: self}).any? do |stmt|
              acc = self.range_compatible_schema?(stmt.object, queryable)
              acc
            end ||
          # Resource also acceptable if it is a List, and every member of the list is range compatible with the predicate
          (list = RDF::List.new(subject: resource, graph: queryable)).valid? && list.all? do |member|
            self.range_compatible_schema?(member, queryable)
          end
        end
      else
        true
      end
    end

    # Are all ranges literal?
    # @param [Array<RDF::UR>] ranges
    # @return [Boolean]
    def literal_range?(ranges)
      ranges.all? do |range|
        case range
        when RDF::RDFS.Literal,
             RDF::URI("http://schema.org/Text"),
             RDF::URI("http://schema.org/Boolean"),
             RDF::URI("http://schema.org/Date"),
             RDF::URI("http://schema.org/DateTime"),
             RDF::URI("http://schema.org/Time"),
             RDF::URI("http://schema.org/URL"),
             RDF::URI("http://schema.org/Number"),
             RDF::URI("http://schema.org/Float"),
             RDF::URI("http://schema.org/Integer"),
             RDF::URI("https://schema.org/Text"),
             RDF::URI("https://schema.org/Boolean"),
             RDF::URI("https://schema.org/Date"),
             RDF::URI("https://schema.org/DateTime"),
             RDF::URI("https://schema.org/Time"),
             RDF::URI("https://schema.org/URL"),
             RDF::URI("https://schema.org/Number"),
             RDF::URI("https://schema.org/Float"),
             RDF::URI("https://schema.org/Integer")
          true
        else
          # If this is an XSD range, look for appropriate literal
          range.start_with?(RDF::XSD.to_s)
        end
      end
    end

    def self.included(mod)
    end

    private
    # Fully entailed types
    def entailed_types(resource, queryable, **options)
      options.fetch(:types) do
        queryable.query({subject: resource, predicate: RDF.type}).
          map {|s| (t = (RDF::Vocabulary.find_term(s.object) rescue nil)) && t.entail(:subClassOf)}.
          flatten.
          uniq.
          compact
      end
    end
  end

  # Extend URI with this methods
  ::RDF::URI.send(:include, Schema)
end