# frozen_string_literal: true

class OaiPressSet < BlacklightOaiProvider::SolrSet
  def description
    "This is a #{label} set containing records with the value of #{value}."
  end
end
