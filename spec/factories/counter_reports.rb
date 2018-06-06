# frozen_string_literal: true

FactoryBot.define do
  factory :counter_report do
    session "MyString"
    institution ""
    noid "validnoid"
    model "FileSet"
    section ""
    section_type ""
    investigation ""
    request ""
    turnaway ""
    access_type ""
  end
end
