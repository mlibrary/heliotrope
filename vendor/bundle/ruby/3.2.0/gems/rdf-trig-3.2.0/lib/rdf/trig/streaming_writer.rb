module RDF::TriG
  ##
  # Streaming writer interface
  # @author [Gregg Kellogg](https://greggkellogg.net/)
  module StreamingWriter
    ##
    # Write out a statement, retaining current
    # `subject` and `predicate` to create more compact output
    # @return [void] `self`
    def stream_statement(statement)
      if statement.graph_name != @streaming_graph
        stream_epilogue
        if statement.graph_name
          @output.write "#{format_term(statement.graph_name, **options)} {"
        end
        @streaming_graph, @streaming_subject, @streaming_predicate = statement.graph_name, statement.subject, statement.predicate
        @output.write "#{format_term(statement.subject, **options)} "
        @output.write "#{statement.predicate == RDF.type ? 'a' : format_term(statement.predicate, **options)} "
      elsif statement.subject != @streaming_subject
        @output.puts " ." if @previous_statement
        @output.write "#{indent(@streaming_subject ? 1 : 0)}"
        @streaming_subject, @streaming_predicate = statement.subject, statement.predicate
        @output.write "#{format_term(statement.subject, **options)} "
        @output.write "#{statement.predicate == RDF.type ? 'a' : format_term(statement.predicate, **options)} "
      elsif statement.predicate != @streaming_predicate
        @streaming_predicate = statement.predicate
        @output.write ";\n#{indent(@streaming_subject ? 2 : 1)}#{statement.predicate == RDF.type ? 'a' : format_term(statement.predicate, **options)} "
      else
        @output.write ",\n#{indent(@streaming_subject ? 3 : 2)}"
      end
      @output.write("#{format_term(statement.object, **options)}")
      @previous_statement = statement
    end

    ##
    # Complete open statements
    # @return [void] `self`
    def stream_epilogue
      case
      when @previous_statement.nil? ;
      when @streaming_graph then @output.puts " }"
      else @output.puts " ."
      end
    end

    private
  end
end
