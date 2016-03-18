FactoryGirl.define do
  factory :press do
    name "MyString"
    logo_path "MyString"
    description "MyText"
    sequence(:subdomain) { |_n| "press-#{srand}" }
  end
end
