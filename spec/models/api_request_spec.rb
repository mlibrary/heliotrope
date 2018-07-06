# frozen_string_literal: true

require 'rails_helper'

RSpec.describe APIRequest, type: :model do
  subject { build(:api_request) }

  it do
    is_expected.to be_valid
    expect(subject.save!).to be true
    expect(subject.destroy!).to be subject
  end
end
