# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Authentication, type: :model do
  subject { described_class.new(args) }

  let(:args) { { email: email } }
  let(:email) { user.email }
  let(:user) { build(:user) }

  it 'is valid' do
    expect(subject).to be_valid
    expect(subject.errors.messages).to be_empty
  end
end
