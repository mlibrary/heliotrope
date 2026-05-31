require 'rdf/turtle/terminals'

module RDF::Turtle
  ##
  # Streaming writer interface
  # @author [Gregg Kellogg](https://greggkellogg.net/)
  module StreamingWriter
    ##
    # Write out declarations
    # @return [void] `self`
    def stream_prologue
      if @options[:standard_prefixes]
        RDF::Vocabulary.each do |vocab|
          pfx = vocab.__name__.to_s.split('::').last.downcase
          prefix(pfx, vocab.to_uri)
        end
      end
      preprocess
      start_document
      @output.puts ""
    end

    ##
    # Write out a statement, retaining current
    # `subject` and `predicate` to create more compact output
    # @return [void] `self`
    def stream_statement(statement)
      if statement.subject != @streaming_subject
        @output.puts ' .' if @streaming_subject
        @streaming_subject, @streaming_predicate = statement.subject, statement.predicate
        @output.write "#{format_term(statement.subject, **options)} "
        @output.write "#{format_term(statement.predicate, **options)} "
      elsif statement.predicate != @streaming_predicate
        @streaming_predicate = statement.predicate
        @output.write ";\n#{indent(1)}#{format_term(statement.predicate, **options)} "
      else
        @output.write ",\n#{indent(2)}"
      end
      @output.write("#{format_term(statement.object, **options)}")
    end

    ##
    # Complete open statements
    # @return [void] `self`
    def stream_epilogue
      @output.puts ' .' if @streaming_subject
    end

    private
  end
end
