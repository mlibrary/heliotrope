# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Guest, type: :model do
  subject { user }

  let(:user) { described_class.new(email: email) }
  let(:email) { 'wolverine@umich.edu' }

  it { is_expected.to be_kind_of(User) }

  context 'save' do
    it { expect { user.save }.to change { User.count }.by(0) }

    it { expect(user.save).to be false }

    it { expect { user.save! }
      .to raise_exception(ActiveRecord::RecordNotSaved)
      .and(change { User.count }.by(0)) }
  end

  context 'create' do
    it { expect { described_class.create(email: email) }
      .to change { User.count }.by(0) }

    it { expect { described_class.create!(email: email) }
      .to raise_exception(ActiveRecord::RecordNotSaved)
      .and(change { User.count }.by(0)) }
  end
end
