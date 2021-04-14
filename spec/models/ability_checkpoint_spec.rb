# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

describe AbilityCheckpoint do
  subject { described_class.new(current_user) }

  context 'nil' do
    let(:current_user) { nil }
    let(:user) { double('user') }

    before { allow(User).to receive(:new).and_return(user) }

    it { expect(subject.current_user).to eq(user) }
    it { is_expected.to be_able_to(:manage, :all) }
  end

  context 'user' do
    let(:current_user) { create(:user) }

    it { expect(subject.current_user).to be current_user }
    it { is_expected.to be_able_to(:manage, :all) }
  end
end
