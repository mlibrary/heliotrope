# frozen_string_literal: true

FactoryBot.define do
  factory :aptrust_upload do
    row_number { 1 }
    noid { "MyNoidsAA" }
    press { "MyPress" }
    author { "MyAuthor" }
    bag_status { 0 }
    s3_status { 0 }
    apt_status { 0 }
    date_monograph_modified { "2019-02-18 14:32:21" }
    date_fileset_modified { "2019-02-18 14:32:21" }
    date_uploaded { "2019-02-18 14:32:21" }
    date_confirmed { "2019-02-18 14:32:21" }
  end
end
