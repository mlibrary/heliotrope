require 'rdf/isomorphic'
require 'rspec/matchers'

Info = Struct.new(:id, :debug, :action, :result, :metadata)

RSpec::Matchers.define :pass_query do |expected, info|
  match do |actual|
    @info = if (info.id rescue false)
      info
    elsif info.is_a?(Hash)
      Info.new(info[:id], info[:logger], info[:action], info.fetch(:result, RDF::Literal::TRUE), info[:metadata])
    end
    @info.debug = Array(@info.debug).join("\n")

    @expected = expected.respond_to?(:read) ? expected.read : expected

    require 'sparql'
    query = SPARQL.parse(@expected)
    @results = actual.query(query)

    @results == @info.result
  end

  failure_message do |actual|
    "#{@info.inspect + "\n"}" +
    if @results.nil?
      "Query failed to return results"
    elsif !@results.is_a?(RDF::Literal::Boolean)
      "Query returned non-boolean results"
    elsif @info.result != @results
      "Query returned false (expected #{@info.result})"
    else
      "Query returned true (expected #{@info.result})"
    end +
    "\n#{@expected}" +
    "\nResults:\n#{@actual.dump(:ttl, standard_prefixes: true, prefixes: {'' => @info.action + '#'}, literal_shorthand: false)}" +
    (@info.metadata ? "\nMetadata:\n#{@info.metadata.to_json(JSON_STATE)}\n" : "") +
    (@info.metadata && !@info.metadata.errors.empty? ? "\nMetadata Errors:\n#{@info.metadata.errors.join("\n")}\n" : "") +
    "\nDebug:\n#{@info.logger}"
  end  

  failure_message_when_negated do |actual|
    "#{@info.inspect + "\n"}" +
    if @results.nil?
      "Query failed to return results"
    elsif !@results.is_a?(RDF::Literal::Boolean)
      "Query returned non-boolean results"
    elsif @info.expectedResults != @results
      "Query returned false (expected #{@info.result})"
    else
      "Query returned true (expected #{@info.result})"
    end +
    "\n#{@expected}" +
    "\nResults:\n#{@actual.dump(:ttl, standard_prefixes: true, prefixes: {'' => @info.action + '#'}, literal_shorthand: false)}" +
    (@info.metadata ? "\nMetadata:\n#{@info.metadata.to_json(JSON_STATE)}\n" : "") +
    (@info.metadata && !@info.metadata.errors.empty? ? "\nMetadata Errors:\n#{@info.metadata.errors.join("\n")}\n" : "") +
    "\nDebug:\n#{@info.logger}"
  end  
end
