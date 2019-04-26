# frozen_string_literal: true

FactoryBot.define do
  factory :crossref_submission_log do
    doi_batch_id { "MyString" }
    initial_http_status { 1 }
    initial_http_message { "MyText" }
    submission_xml { "MyText" }
    status { "MyString" }
    response_xml { "MyText" }
  end
end
