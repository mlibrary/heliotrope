class DummyResourceB
  include ActiveTriples::RDFSource
  configure :type => RDF::URI('http://example.org/type/ResourceB')
  property :label, :predicate => RDF::URI('http://example.org/ontology/label')
  property :in_resource, :predicate => RDF::URI('http://example.org/ontology/in_resource'), :class_name => DummyResourceA
end
