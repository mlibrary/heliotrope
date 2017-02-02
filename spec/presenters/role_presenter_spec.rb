require 'rails_helper'

describe RolePresenter do
  let(:role) { double("role") }
  let(:user) { double("user") }
  let(:current_user) { double("current_user") }

  describe '#initialize' do
    subject { described_class.new(role, user, current_user) }
    it { expect(subject.role).to eq role }
    it { expect(subject.user).to eq user }
    it { expect(subject.current_user).to eq current_user }
  end

  describe 'delegate' do
    subject { described_class.new(role, user, current_user) }
    context 'verify dependencies' do
      it { expect(Role.new).to respond_to(:id) }
    end
    context 'verify methods are delegated to role' do
      before { allow(role).to receive(:id).and_return(:id) }
      it { expect(subject.id).to equal :id }
    end
  end

  context 'verify dependencies' do
    it { expect(Role.new).to respond_to(:resource_id) }
    it { expect(Role.new).to respond_to(:role) }
    it { expect(Press).to respond_to(:find) }
    it { expect(Press.new).to respond_to(:subdomain) }
  end

  describe '#name' do
    subject { described_class.new(role, user, current_user).name }
    let(:expected_role) { "role" }
    context 'role with nil resource' do
      before do
        allow(role).to receive(:resource_id).and_return(nil)
        allow(role).to receive(:role).and_return(expected_role)
      end
      it { expect(subject).to be_a String }
      it { expect(subject).to eq expected_role }
    end
    context 'role with press resource' do
      let(:press) { double("press") }
      let(:expected_subdomain) { "subdomain" }
      before do
        allow(role).to receive(:resource_id).and_return(1)
        allow(role).to receive(:role).and_return(expected_role)
        allow(Press).to receive(:find).and_return(press)
        allow(press).to receive(:subdomain).and_return(expected_subdomain)
      end
      it { expect(subject).to be_a String }
      it { expect(subject).to eq "#{expected_role} (#{expected_subdomain})" }
    end
  end

  describe '#press?' do
    subject { described_class.new(role, user, current_user).press? }
    context 'role with nil resource' do
      before { allow(role).to receive(:resource_id).and_return(nil) }
      it { expect(subject).to be false }
    end
    context 'role with press resource' do
      let(:press) { double("press") }
      before do
        allow(role).to receive(:resource_id).and_return(1)
        allow(Press).to receive(:find).and_return(press)
      end
      it { expect(subject).to be true }
    end
  end

  describe '#press' do
    subject { described_class.new(role, user, current_user).press }
    context 'role with nil resource' do
      before do
        allow(role).to receive(:resource_id).and_return(nil)
      end
      it { expect(subject).to be nil }
    end
    context 'role with press resource' do
      let(:press) { double("press") }
      before do
        allow(role).to receive(:resource_id).and_return(1)
        allow(Press).to receive(:find).and_return(press)
      end
      it { expect(subject).to eql press }
    end
  end

  describe '#can_read?' do
    subject { described_class.new(role, user, current_user).can_read? }
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
      subject { described_class.new(role, current_user, current_user).can_read? }
      it { expect(subject).to be true }
    end
    context 'non admin' do
      before { allow(role).to receive(:resource_id).and_return(nil) }
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
          allow(role).to receive(:resource_id).with(no_args).and_return(1)
          allow(Press).to receive(:find).with(1).and_return(press2)
        end
        it { expect(subject).to be false }
      end
      context 'same press' do
        before do
          allow(current_user).to receive(:admin_presses).and_return([press1])
          allow(user).to receive(:presses).and_return([press1])
          allow(role).to receive(:resource_id).with(no_args).and_return(1)
          allow(Press).to receive(:find).with(1).and_return(press1)
        end
        it { expect(subject).to be true }
      end
    end
  end
end
