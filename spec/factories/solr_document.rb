# frozen_string_literal: true

FactoryGirl.define do
  factory :solr_document do
    initialize_with { new(id: :id, Solrizer.solr_name('title') => ['UNTITLED']) }
  end
end
