require 'rdf'
require 'rdf/ntriples'

module RDF::Turtle
  ##
  # Parser specifically for Freebase, which has a very regular form.
  #
  # @see https://developers.google.com/freebase/data
  class FreebaseReader < RDF::NTriples::Reader
    include RDF::Turtle::Terminals

    def self.format; RDF::Turtle::Format; end

    ##
    # Extension to N-Triples reader, includes reading
    # pnames and prefixes
    def read_triple
      loop do
        begin
          readline.strip!
          line = @line
          unless blank? || read_prefix
            subject   = read_pname(intern:  true) || fail_subject
            predicate = read_pname(intern:  true) || fail_predicate
            object    = read_pname || read_uriref || read_boolean || read_numeric || read_literal || fail_object
            if validate? && !read_eos
              log_error("Expected end of statement (found: #{current_line.inspect})", lineno: lineno, exception: RDF::ReaderError)
            end
            return [subject, predicate, object]
          end
        rescue RDF::ReaderError =>  e
          raise e if validate?
          if @options[:errors]
            @options[:errors] << e.message
          else
            $stderr.puts e.message
          end
        end
      end
    end

    ##
    # Read a prefix of the form `@prefix pfx: <uri> .
    #
    # Add prefix definition to `prefixes`
    # @return [RDF::URI]
    def read_prefix
      if prefix_str = match(/^@prefix\s+(\w+:\s+#{IRIREF})\s*.$/)
        prefix, iri = prefix_str.split(/:\s+/)
        return nil unless iri
        prefix(prefix, iri[1..-2])
      end
    end

    ##
    # Read a PNAME of the form `prefix:suffix`.
    # @return [RDF::URI]
    def read_pname(**options)
      if pname_str = match(/^(\w+:\S+)/)
        ns, suffix = pname_str.split(':', 2)
        if suffix[-1,1] == "."
          suffix.chop!  # Remove end of statement
          @line.insert(0, ".")
        end
        pfx_iri = prefix(ns)
        raise RDF::ReaderError.new("ERROR [line #{lineno}] prefix #{ns.inspect} is not defined", lineno: lineno) unless pfx_iri
        uri = RDF::URI(pfx_iri + suffix)
        uri.validate!     if validate?
        uri
      end
    rescue ArgumentError => e
      raise RDF::ReaderError.new("ERROR [line #{lineno}] invalid PName", lineno: lineno)
    end

    ##
    # @return [RDF::Literal]
    # @see    https://www.w3.org/TR/rdf-testcases/#ntrip_grammar (literal)
    def read_literal
      if literal_str = match(LITERAL_PLAIN)
        literal_str = self.class.unescape(literal_str)
        literal = case
          when language = match(RDF::NTriples::Reader::LANGTAG)
            RDF::Literal.new(literal_str, language:  language)
          when datatype = match(/^(\^\^)/)
            RDF::Literal.new(literal_str, datatype:  read_pname(intern:  true) || read_uriref || fail_object)
          else
            RDF::Literal.new(literal_str) # plain string literal
        end
        literal.validate!     if validate?
        literal.canonicalize! if canonicalize?
        literal
      end
    end

    ##
    # Read a numeric value
    # @return [RDF::Literal::Integer, RDF::Literal::Float, RDF::Literal::Double]
    def read_numeric
      case
      when double_str = match(/^(#{DOUBLE})/)
        double_str = double_str.sub(/\.([eE])/, '.0\1')
        RDF::Literal::Double.new(double_str, canonicalize:  canonicalize?)
      when decimal_str = match(/^(#{DECIMAL})/)
        decimal_str = "0#{decimal_str}" if decimal_str[0,1] == "."
        RDF::Literal::Decimal.new(decimal_str, canonicalize:  canonicalize?)
      when integer_str = match(/^(#{INTEGER})/)
        RDF::Literal::Integer.new(integer_str, canonicalize:  canonicalize?)
      end
    end

    ##
    # Read a boolean value
    # @return [RDF::Literal::Boolean]
    def read_boolean
      if bool_str = match(/^(true|false)/)
        RDF::Literal::Boolean.new(bool_str, canonicalize:  canonicalize?)
      end
    end
  end # class Reader
end # module RDF::Turtle
