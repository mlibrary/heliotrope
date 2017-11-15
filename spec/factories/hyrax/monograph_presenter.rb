# frozen_string_literal: true

FactoryBot.define do
  factory :monograph_presenter, class: Hyrax::MonographPresenter do
    initialize_with { new(build(:solr_document), build(:ability), nil) }
  end
end
