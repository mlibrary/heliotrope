# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Individual, type: :model do
  subject { described_class.new(identifier: "identifier", name: "name", email: "email") }

  it do
    is_expected.to be_valid
    expect(subject.destroy?).to be true
  end
end
