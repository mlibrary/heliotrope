# frozen_string_literal: true

class CounterReport < ApplicationRecord
  # COUNTER v5 section 3.3.5
  validates :access_type, inclusion: { in: %w[Controlled OA_Gold] }

  # We probably won't use Limit_Exceeded but it's allowed
  # COUNTER v5 section 3.3.4
  validates :turnaway, inclusion: { in: [nil, "", "No_License", "Limit_Exceeded"] }

  # Really we only want "Chapter" here for the forseeable future.
  # COUNTER v5 section 3.3.3
  # We'll use the higher level "Data_Type" for other things (which we can infer
  # from solr so we don't need to collect it in this table)
  # COUNTER v5 section 3.3.2
  validates :section_type, inclusion: { in: [nil, "", "Article", "Book", "Chapter", "Other", "Section"] }
end
