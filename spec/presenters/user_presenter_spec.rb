# frozen_string_literal: true

require 'rails_helper'

describe UserPresenter do
  let(:user) { double("user") }
  let(:current_user) { double("current_user") }

  describe '#initialize' do
    subject { described_class.new(user, current_user) }

    it { expect(subject.user).to eq user }
    it { expect(subject.current_user).to eq current_user }
  end

  describe 'delegate' do
    subject { described_class.new(user, current_user) }

    context 'verify dependencies' do
      it { expect(User.new).to respond_to(:id) }
      it { expect(User.new).to respond_to(:email) }
    end

    context 'verify methods are delegated to user' do
      before do
        allow(user).to receive(:id).and_return(:id)
        allow(user).to receive(:email).and_return(:email)
      end

      it { expect(subject.id).to equal :id }
      it { expect(subject.email).to equal :email }
    end
  end

  describe '#roles?' do
    subject { described_class.new(user, current_user).roles? }

    context 'verify dependencies' do
      it { expect(User.new).to respond_to(:roles) }
    end

    context "when no roles" do
      before { allow(user).to receive(:roles).and_return([]) }

      it { is_expected.to be false }
    end

    context "when at least one role" do
      let(:role) { double("role") }

      before { allow(user).to receive(:roles).and_return([role]) }

      it { is_expected.to be true }
    end
  end

  describe '#roles' do
    subject { described_class.new(user, current_user).roles }

    it { expect(subject).to be_a RolesPresenter }
    it { expect(subject.user).to eq user }
    it { expect(subject.current_user).to eq current_user }
  end

  describe '#can_read?' do
    subject { described_class.new(user, current_user).can_read? }

    before do
      allow(current_user).to receive(:platform_admin?).and_return(false)
      allow(current_user).to receive(:admin_presses).and_return([])
      allow(user).to receive(:presses).and_return([])
    end

    context 'verify dependencies' do
      it { expect(User.new).to respond_to(:platform_admin?) }
      it { expect(User.new).to respond_to(:presses) }
      it { expect(User.new).to respond_to(:admin_presses) }
    end

    context 'current user is user' do
      subject { described_class.new(current_user, current_user).can_read? }

      it { expect(subject).to be true }
    end

    context 'non admin' do
      it { expect(subject).to be false }
    end

    context 'platform admin' do
      before { allow(current_user).to receive(:platform_admin?).and_return(true) }

      it { expect(subject).to be true }
    end

    context 'press admin' do
      let(:press1) { double("press1") }
      let(:press2) { double("press2") }

      context 'different press' do
        before do
          allow(current_user).to receive(:admin_presses).and_return([press1])
          allow(user).to receive(:presses).and_return([press2])
        end

        it { expect(subject).to be false }
      end

      context 'same press' do
        before do
          allow(current_user).to receive(:admin_presses).and_return([press1])
          allow(user).to receive(:presses).and_return([press1])
        end

        it { expect(subject).to be true }
      end
    end
  end
end
