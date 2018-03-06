# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subscription, type: :model do
  subject { described_class.new(args) }

  let(:args) { { subscriber: subscriber.id, publication: publication.id } }
  let(:subscriber) { Entity.new(type: :email, identifier: 'user@domain.com') }
  let(:publication) { Entity.new(type: :epub, identifier: 'validnoid') }

  it 'is valid' do
    expect(subject).to be_valid
    expect(subject.errors.messages).to be_empty
  end
end
