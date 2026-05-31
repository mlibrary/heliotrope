# -*- encoding: utf-8 -*-
# frozen_string_literal: true
# This file generated automatically using rdf vocabulary format from http://pcdm.org/use#
require 'rdf'
module Valkyrie::Vocab
  # @!parse
  #   # Vocabulary for <http://pcdm.org/use#>
  #   class PCDMUse < RDF::Vocabulary
  #   end
  class PCDMUse < RDF::Vocabulary("http://pcdm.org/use#")
    # Ontology definition
    ontology :"http://pcdm.org/use#",
             comment: %(Ontology for a PCDM extension to add subclasses of PCDM File for the
               different roles files have in relation to the Object they are attached to.),
             "dc:modified": %(2015-05-12),
             "dc:publisher": %(http://www.duraspace.org/),
             "dc:title": %(Portland Common Data Model: Use Extension),
             "owl:versionInfo": %(2015/05/12),
             "rdfs:seeAlso": [%(https://github.com/duraspace/pcdm/wiki), %(https://wiki.duraspace.org/display/hydra/File+Use+Vocabulary)]

    # Class definitions
    term :ExtractedText,
         comment: %(A textual representation of the Object appropriate for fulltext indexing,
           such as a plaintext version of a document, or OCR text.),
         label: "extracted text",
         "rdf:subClassOf": %(http://pcdm.org/resources#File),
         "rdfs:isDefinedBy": %(pcdmuse:),
         type: "rdfs:Class"
    term :IntermediateFile,
         comment: %(High quality representation of the Object, appropriate for generating
           derivatives or other additional processing.),
         label: "intermediate file",
         "rdf:subClassOf": %(http://pcdm.org/resources#File),
         "rdfs:isDefinedBy": %(pcdmuse:),
         type: "rdfs:Class"
    term :OriginalFile,
         comment: %(The original creation format of a file.),
         label: "original file",
         "rdf:subClassOf": %(http://pcdm.org/resources#File),
         "rdfs:isDefinedBy": %(pcdmuse:),
         type: "rdfs:Class"
    term :PreservationFile,
         comment: %(Best quality representation of the Object appropriate for long-term
           preservation.),
         label: "preservation file",
         "dct:replaces": %(http://pcdm.org/use#PreservationMasterFile),
         "rdf:subClassOf": %(http://pcdm.org/resources#File),
         "rdfs:isDefinedBy": %(pcdmuse:),
         type: "rdfs:Class"
    warn "[DEPRECATION] PCDM is deprecating '#{name}#PreservationMasterFile'. Use '#{name}#PreservationFile' instead. " \
         "This warning does *not* indicate that usage of the deprecated term has been detected."
    # @deprecated
    term :PreservationMasterFile,
         comment: %(Best quality representation of the Object appropriate for long-term
           preservation.),
         label: "preservation master file",
         "dct:isReplacedBy": %(http://pcdm.org/use#PreservationFile),
         "owl:deprecated": true,
         "rdf:subClassOf": %(http://pcdm.org/resources#File),
         "rdfs:isDefinedBy": %(pcdmuse:),
         type: "rdfs:Class"
    term :ServiceFile,
         comment: %(A medium quality representation of the Object appropriate for serving to
           users.  Similar to a FADGI "derivative file" but can also be used for born-digital content,
           and is not necessarily derived from another file.),
         label: "service file",
         "rdf:subClassOf": %(http://pcdm.org/resources#File),
         "rdfs:isDefinedBy": %(pcdmuse:),
         type: "rdfs:Class"
    term :ThumbnailImage,
         comment: %(A low resolution image representation of the Object appropriate for using
           as an icon.),
         label: "thumbnail image",
         "rdf:subClassOf": %(http://pcdm.org/resources#File),
         "rdfs:isDefinedBy": %(pcdmuse:),
         type: "rdfs:Class"
    term :Transcript,
         comment: %(A textual representation of the Object appropriate for presenting to users,
           such as subtitles or transcript of a video.  Can be used as a substitute or complement to other
           files for accessibility purposes.),
         label: "transcript",
         "rdf:subClassOf": %(http://pcdm.org/resources#ExtractedText),
         "rdfs:isDefinedBy": %(pcdmuse:),
         type: "rdfs:Class"
  end
end
