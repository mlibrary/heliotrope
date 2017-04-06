require 'rails_helper'

describe ApplicationPresenter do
  let(:current_user) { double("current_user") }

  describe '#initialize' do
    subject { described_class.new(current_user) }
    it { expect(subject.current_user).to eq current_user }
  end

  describe 'delegate' do
    subject { described_class.new(current_user) }
    context 'verify dependencies' do
      it { expect(User.new).to respond_to(:platform_admin?) }
    end
    context 'verify methods are delegated to current user' do
      before do
        allow(current_user).to receive(:platform_admin?).and_return(:platform_admin?)
      end
      it { expect(subject.platform_admin?).to equal :platform_admin? }
    end
  end

  describe '#can_read?' do
    let(:is_platform_admin) { double("is_platform_admin") }
    subject { described_class.new(current_user).can_read? }
    before do
      allow(current_user).to receive(:platform_admin?).and_return(is_platform_admin)
    end
    context 'verify dependencies' do
      it { expect(User.new).to respond_to(:platform_admin?) }
    end
    context 'non admin' do
      let(:is_platform_admin) { false }
      it { expect(subject).to be false }
    end
    context 'admin' do
      let(:is_platform_admin) { true }
      it { expect(subject).to be true }
    end
  end
end
