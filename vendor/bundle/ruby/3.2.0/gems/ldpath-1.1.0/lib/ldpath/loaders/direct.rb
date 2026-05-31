class Ldpath::Loaders::Direct
  def load(uri)
    Ldpath.logger.debug "Loading #{uri.inspect}"

    reader_types = RDF::Format.reader_types.reject { |t| t.to_s =~ /html/ }.map do |t|
      t.to_s =~ %r{text/(?:plain|html)} ? "#{t};q=0.5" : t
    end

    RDF::Graph.load(uri, headers: { 'Accept' => reader_types.join(", ") })
  end
end
