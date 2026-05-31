module Hydra::Works::Characterization
  class DocumentSchema < ActiveTriples::Schema
    property :file_title, predicate: RDF::Vocab::DC11.title
    property :creator, predicate: RDF::Vocab::DC11.creator
    property :page_count, predicate: RDF::Vocab::NFO.pageCount
    property :language, predicate: RDF::Vocab::DC11.language
    property :word_count, predicate: RDF::Vocab::NFO.wordCount
    property :character_count, predicate: RDF::Vocab::NFO.characterCount
    property :line_count, predicate: RDF::Vocab::NFO.lineCount
    property :character_set, predicate: RDF::URI.new("http://www.w3.org/2011/content#characterEncoding")
    property :markup_basis, predicate: RDF::URI.new("http://www.w3.org/2011/content#doctypeName")
    property :markup_language, predicate: RDF::URI.new("http://www.w3.org/2011/content#systemId")
    # properties without canonical URIs
    property :paragraph_count, predicate: RDF::URI.new("http://projecthydra.org/ns/odf/paragraphCount")
    property :table_count, predicate: RDF::URI.new("http://projecthydra.org/ns/odf/tableCount")
    property :graphics_count, predicate: RDF::URI.new("http://projecthydra.org/ns/odf/graphicsCount")
  end
end
