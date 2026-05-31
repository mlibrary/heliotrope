module RDF
  class MD < Vocabulary("http://www.w3.org/ns/md#")
    property :item,
      label: "item",
      comment: "List of items",
      type: "rdf:Property",
      range: "rdf:List"
  end
  class HCard < Vocabulary("http://microformats.org/profile/hcard#"); end
  class HCalendar < Vocabulary("http://microformats.org/profile/hcalendar"); end
end
