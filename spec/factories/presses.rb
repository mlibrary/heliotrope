# frozen_string_literal: true

FactoryBot.define do
  factory :press do
    sequence(:name) { |n| "Press #{n}" }
    sequence(:description) { |n| "Description of Press #{n}" }
    sequence(:press_url) { |n| "http://www.external_link_to_press#{n}" }
    sequence(:google_analytics) { |n| "UA-87654321-#{n}" }
    logo_path do
      Rack::Test::UploadedFile.new(File.open(Rails.root.join('spec', 'fixtures', 'csv', 'import', 'shipwreck.jpg')), 'image/jpg')
    end
    sequence(:subdomain) { |_n| "press-#{srand}" }
  end
end
