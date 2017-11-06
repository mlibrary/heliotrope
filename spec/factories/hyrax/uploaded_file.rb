# frozen_string_literal: true

FactoryGirl.define do
  factory :uploaded_file, class: Hyrax::UploadedFile do
    user
    file do
      file
    end
  end
end
