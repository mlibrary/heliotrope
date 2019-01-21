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

  context 'platform_admin' do
    let(:current_user) { create(:platform_admin) }

    describe "#platform_admin?" do
      subject { described_class.new(current_user).platform_admin? }

      it { is_expected.to be true }
    end

    describe "#admin?" do
      subject { described_class.new(current_user).admin? }

      it { is_expected.to be true }
    end
  end

  context 'press_admin' do
    let(:press) { create(:press) }
    let(:current_user) { create(:press_admin, press: press) }

    describe '#admin_for?' do
      subject { described_class.new(current_user).admin_for?(press) }

      it { is_expected.to be true }
    end
  end
end
