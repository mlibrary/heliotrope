# frozen_string_literal: true

# TODO: remove this file and references to it once the dust setlles on multi-line creator work

module StoresCreatorNameSeparately
  extend ActiveSupport::Concern

  included do
    # The primary creator's family name and given name are
    # stored in separate properties in the fedora record.
    property :creator_family_name, predicate: ::RDF::Vocab::FOAF.family_name, multiple: false do |index|
      index.as :stored_searchable
    end

    property :creator_given_name, predicate: ::RDF::Vocab::FOAF.givenname, multiple: false do |index|
      index.as :stored_searchable
    end
  end
end
