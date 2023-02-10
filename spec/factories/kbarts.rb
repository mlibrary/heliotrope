# frozen_string_literal: true

FactoryBot.define do
  factory :kbart do
    noid { "MyString" }
    publication_title { "MyText" }
    print_identifier { "MyString" }
    online_identifier { "MyString" }
    date_first_issue_online { "MyString" }
    num_first_vol_online { "MyString" }
    num_first_issue_online { "MyString" }
    date_last_issue_onlline { "MyString" }
    num_last_vol_online { "MyString" }
    num_last_issue_online { "MyString" }
    title_url { "MyString" }
    first_author { "MyString" }
    title_id { "MyString" }
    embargo_info { "MyString" }
    coverage_depth { "MyString" }
    coverage_notes { "MyString" }
    publisher_name { "MyString" }
  end
end
