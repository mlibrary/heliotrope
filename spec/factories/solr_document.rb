# frozen_string_literal: true

FactoryBot.define do
  factory :solr_document do
    initialize_with { new(id: :id, 'title_tesim' => ['UNTITLED']) }
  end
end
