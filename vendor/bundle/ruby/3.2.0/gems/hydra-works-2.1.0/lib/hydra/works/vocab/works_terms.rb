require 'rdf'
module Hydra::Works
  module Vocab
    class WorksTerms < RDF::Vocabulary('http://projecthydra.org/works/models#')
      # Class definitions
      term :Collection
      term :Work
      term :FileSet
      term :File
    end
  end
end
