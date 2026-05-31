require 'rdf/turtle'

module RDF::TriG
  ##
  # A parser for the TriG
  #
  # Leverages the Turtle reader
  class Reader < RDF::Turtle::Reader
    format Format

    # Terminals passed to lexer. Order matters!
    terminal(:ANON,                             ANON)
    terminal(:BLANK_NODE_LABEL,                 BLANK_NODE_LABEL)
    terminal(:IRIREF,                           IRIREF, unescape:  true)
    terminal(:DOUBLE,                           DOUBLE)
    terminal(:DECIMAL,                          DECIMAL)
    terminal(:INTEGER,                          INTEGER)
    terminal(:PNAME_LN,                         PNAME_LN, unescape:  true)
    terminal(:PNAME_NS,                         PNAME_NS)
    terminal(:STRING_LITERAL_LONG_SINGLE_QUOTE, STRING_LITERAL_LONG_SINGLE_QUOTE, unescape:  true, partial_regexp: /^'''/)
    terminal(:STRING_LITERAL_LONG_QUOTE,        STRING_LITERAL_LONG_QUOTE,        unescape:  true, partial_regexp: /^"""/)
    terminal(:STRING_LITERAL_QUOTE,             STRING_LITERAL_QUOTE,             unescape:  true)
    terminal(:STRING_LITERAL_SINGLE_QUOTE,      STRING_LITERAL_SINGLE_QUOTE,      unescape:  true)
 
    # String terminals
    terminal(nil,                               %r(
                                                    [\(\),.;\[\]Aa]
                                                  | \^\^
                                                  | \{\|
                                                  | \|\}
                                                  | [\{\}]
                                                  | true|false
                                                  | <<|>>
                                                )x)

    terminal(:GRAPH,                            /graph/i)
    terminal(:PREFIX,                           PREFIX)
    terminal(:BASE,                             BASE)
    terminal(:LANGTAG,                          LANGTAG)

    ##
    # Iterates the given block for each RDF statement in the input.
    #
    # @yield  [statement]
    # @yieldparam [RDF::Statement] statement
    # @return [void]
    def each_statement(&block)
      if block_given?
        @recovering = false
        @callback = block

        begin
          while (@lexer.first rescue true)
            read_trigDoc
          end
        rescue EBNF::LL1::Lexer::Error, SyntaxError, EOFError, Recovery
          # Terminate loop if EOF found while recovering
        end

        if validate? && log_statistics[:error]
          raise RDF::ReaderError, "Errors found during processing"
        end
      end
      enum_for(:each_statement)
    end

    ##
    # Iterates the given block for each RDF quad in the input.
    #
    # @yield  [subject, predicate, object, graph_name]
    # @yieldparam [RDF::Resource] subject
    # @yieldparam [RDF::URI]      predicate
    # @yieldparam [RDF::Value]    object
    # @yieldparam [RDF::URI]      graph_name
    # @return [void]
    def each_quad(&block)
      if block_given?
        each_statement do |statement|
          block.call(*statement.to_quad)
        end
      end
      enum_for(:each_quad)
    end

    # add a statement, object can be literal or URI or bnode
    #
    # @param [Symbol] production
    # @param [RDF::Statement] statement the subject of the statement
    # @return [RDF::Statement] Added statement
    # @raise [RDF::ReaderError] Checks parameter types and raises if they are incorrect if parsing mode is _validate_.
    def add_statement(production, statement)
      error("Statement is invalid: #{statement.inspect.inspect}", production: produciton) if validate? && statement.invalid?
      statement.graph_name = @graph_name if @graph_name
      @callback.call(statement) if statement.subject &&
                                   statement.predicate &&
                                   statement.object &&
                                   (validate? ? statement.valid? : true)
    end

  protected
    # @return [Object]
    def read_trigDoc
      prod(:trigDoc, %(} .)) do
        read_directive || read_block
      end
    end

    # @return [Object]
    def read_block
      prod(:block, %(})) do
        @graph_name = nil
        token = @lexer.first
        case token && (token.type || token.value)
        when :GRAPH
          @lexer.shift
          @graph_name = read_labelOrSubject || error("Expected label or subject", production: :block, token: @lexer.first)
          read_wrappedGraph || error("Expected wrappedGraph", production: :block, token: @lexer.first)
          @graph_name = nil
        when :IRIREF, :BLANK_NODE_LABEL, :ANON, :PNAME_LN, :PNAME_NS
          read_triplesOrGraph || error("Expected triplesOrGraph", production: :block, token: @lexer.first)
        when '{'
          read_wrappedGraph || error("Expected wrappedGraph", production: :block, token: @lexer.first)
        when '(', '[', '<<'
          read_triples2 || error("Expected collection or blankNodePropertyList", production: :block, token: @lexer.first)
        when nil
          # End of input
        else
          error("Unexpected token: #{@lexer.first.inspect}", production: :block, token: @lexer.first)
        end
      end
    end

    # @return [Object]
    def read_triplesOrGraph
      while name = read_labelOrSubject
        prod(:triplesOrGraph, %(} .)) do
          token = @lexer.first
          case token && token.value
          when '{'
            @graph_name = name
            read_wrappedGraph || error("Expected wrappedGraph", production: :triplesOrGraph, token: @lexer.first)
            @graph_name = nil
            true
          else
            read_predicateObjectList(name) || error("Expected predicateObjectList", production: :triplesOrGraph, token: @lexer.first)
            unless @recovering
              # If recovering, we will have eaten the closing '.'
              token = @lexer.shift
              unless token && token.value == '.'
                error("Expected '.' following triple", production: :triplesOrGraph, token: token)
              end
            end
          end
        end
      end
      true
    end

    # @return [Object]
    def read_triples2
      token = @lexer.first
      case token && token.value
      when '['
        prod(:triples2) do
          # blankNodePropertyList predicateObjectList? 
          subject = read_blankNodePropertyList || error("Failed to parse blankNodePropertyList", production: :triples2, token: @lexer.first)
          read_predicateObjectList(subject)
          if !@recovering || @lexer.first === '.'
            # If recovering, we will have eaten the closing '.'
            token = @lexer.shift
            unless token && token.value == '.'
              error("Expected '.' following triple", production: :triples2, token: token)
            end
          end
          true
        end
      when '('
        prod(:triples2) do
          subject = read_collection || error("Failed to parse read_collection", production: :triples2, token: @lexer.first)
          token = @lexer.first
          case token && (token.type || token.value)
          when 'a', :IRIREF, :PNAME_LN, :PNAME_NS then read_predicateObjectList(subject)
          else error("Expected predicateObjectList after collection subject", production: :triples2, token: token)
          end
          if !@recovering || @lexer.first === '.'
            # If recovering, we will have eaten the closing '.'
            token = @lexer.shift
            unless token && token.value == '.'
              error("Expected '.' following triple", production: :triples2, token: token)
            end
          end
          true
        end
      when '<<'
        prod(:triples2) do
          subject = read_quotedTriple || error("Failed to parse embedded triple", production: :triples2, token: @lexer.first)
          token = @lexer.first
          case token && (token.type || token.value)
          when 'a', :IRIREF, :PNAME_LN, :PNAME_NS then read_predicateObjectList(subject)
          else error("Expected predicateObjectList after collection subject", production: :triples2, token: token)
          end
          if !@recovering || @lexer.first === '.'
            # If recovering, we will have eaten the closing '.'
            token = @lexer.shift
            unless token && token.value == '.'
              error("Expected '.' following triple", production: :triples2, token: token)
            end
          end
          true
        end
      end
    end

    # @return [Object]
    def read_wrappedGraph
      token = @lexer.first
      if token && token.value == '{'
        prod(:wrappedGraph, %w(})) do
          @lexer.shift
          while read_triplesBlock
            # Read until nothing found
          end
          if !@recovering || @lexer.first === '}'
            # If recovering, we will have eaten the closing '}'
            token = @lexer.shift
            unless token && token.value == '}'
              error("Expected '}' following triple", production: :wrappedGraph, token: token)
            end
          end
          true
        end
      end
    end

    # @return [Object]
    def read_triplesBlock
      prod(:triplesBlock, %w(.)) do
        while (token = @lexer.first) && token.value != '}' && read_triples
          unless log_recovering?
            break unless @lexer.first === '.'
            @lexer.shift
          end
        end
      end
    end

    # @return [RDF::Resource]
    def read_labelOrSubject
      prod(:labelOrSubject) do
        read_iri || read_BlankNode
      end
    end

  end # class Reader
end # module RDF::Turtle
