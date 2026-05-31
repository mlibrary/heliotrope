class DummyResourceA
  include ActiveTriples::RDFSource
  configure :type => RDF::URI('http://example.org/type/ResourceA')
  property :label, :predicate => RDF::URI('http://example.org/ontology/label')
  property :has_resource, :predicate => RDF::URI('http://example.org/ontology/has_resource'), :class_name => DummyResourceB
end
