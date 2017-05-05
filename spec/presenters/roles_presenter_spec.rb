# frozen_string_literal: true

require 'rails_helper'

describe RolesPresenter do
  let(:user) { double("user") }
  let(:current_user) { double("current_user") }

  describe '#initialize' do
    subject { described_class.new(user, current_user) }
    it { expect(subject.user).to eq user }
    it { expect(subject.current_user).to eq current_user }
  end

  describe '#all' do
    subject { described_class.new(user, current_user).all }
    before { allow(user).to receive(:roles).and_return([]) }
    context 'verify dependencies' do
      it { expect(User.new).to respond_to(:roles) }
      it { expect(Role.new).to respond_to(:resource_id) }
      it { expect(Role.new).to respond_to(:role) }
    end
    context 'without roles' do
      it { expect(subject).to be_a Array }
      it { expect(subject).to be_empty }
    end
    context 'with role' do
      let(:role) { double("role") }
      before { allow(user).to receive(:roles).and_return([role]) }
      it { expect(subject).to be_a Array }
      it { expect(subject).to_not be_empty }
      it { expect(subject[0]).to be_a RolePresenter }
      it { expect(subject[0].role).to eq role }
      it { expect(subject[0].user).to eq user }
      it { expect(subject[0].current_user).to eq current_user }
    end
    context 'with roles' do
      let(:role1) { double("role1") }
      let(:role2) { double("role2") }
      before do
        allow(user).to receive(:roles).and_return([role1, role2])
        allow(role1).to receive(:resource_id).and_return(nil)
        allow(role1).to receive(:role).and_return("z")
        allow(role2).to receive(:resource_id).and_return(nil)
        allow(role2).to receive(:role).and_return("a")
      end
      it { expect(subject).to be_a Array }
      it { expect(subject).to_not be_empty }
      it { expect(subject[0]).to be_a RolePresenter }
      it { expect(subject[0].role).to eq role2 }
      it { expect(subject[0].user).to eq user }
      it { expect(subject[0].current_user).to eq current_user }
      it { expect(subject[1]).to be_a RolePresenter }
      it { expect(subject[1].role).to eq role1 }
      it { expect(subject[1].user).to eq user }
      it { expect(subject[1].current_user).to eq current_user }
    end
  end

  describe '#can_read?' do
    subject { described_class.new(user, current_user).can_read? }
    context 'all users' do
      it { expect(subject).to be true }
    end
  end
end
