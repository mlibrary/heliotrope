# frozen_string_literal: true

FactoryBot.define do
  factory :job_status do
    command { "MyString" }
    task { "MyString" }
    noid { "MyString" }
    completed { false }
    error { false }
    error_message { "MyText" }
  end
end
