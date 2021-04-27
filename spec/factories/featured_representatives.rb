# frozen_string_literal: true

FactoryBot.define do
  factory :featured_representative do
    work_id { Noid::Rails::Service.new.mint }
    file_set_id { Noid::Rails::Service.new.mint }
    kind { "epub" }
  end
end
