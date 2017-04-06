require 'rails_helper'

describe UsersPresenter do
  let(:current_user) { double("current_user") }

  describe '#initialize' do
    subject { described_class.new(current_user) }
    it { expect(subject.current_user).to eq current_user }
  end

  describe '#all' do
    subject { described_class.new(current_user).all }
    before { allow(User).to receive(:all).and_return([]) }
    context 'verify dependencies' do
      it { expect(User).to respond_to(:all) }
      it { expect(User.new).to respond_to(:email) }
    end
    context 'without users' do
      it { expect(subject).to be_a Array }
      it { expect(subject).to be_empty }
    end
    context 'with user' do
      let(:user) { double("user") }
      before { allow(User).to receive(:all).and_return([user]) }
      it { expect(subject).to be_a Array }
      it { expect(subject).to_not be_empty }
      it { expect(subject[0]).to be_a UserPresenter }
      it { expect(subject[0].user).to eq user }
      it { expect(subject[0].current_user).to eq current_user }
    end
    context 'with users sorted on email' do
      let(:user1) { double("user1") }
      let(:user2) { double("user2") }
      before do
        allow(User).to receive(:all).and_return([user1, user2])
        allow(user1).to receive(:email).and_return("z")
        allow(user2).to receive(:email).and_return("a")
      end
      it { expect(subject).to be_a Array }
      it { expect(subject).to_not be_empty }
      it { expect(subject[0]).to be_a UserPresenter }
      it { expect(subject[0].user).to eq user2 }
      it { expect(subject[0].current_user).to eq current_user }
      it { expect(subject[1]).to be_a UserPresenter }
      it { expect(subject[1].user).to eq user1 }
      it { expect(subject[1].current_user).to eq current_user }
    end
  end

  describe '#can_read?' do
    subject { described_class.new(current_user).can_read? }
    let(:roles) { double("roles") }
    before do
      allow(current_user).to receive(:roles).and_return(roles)
      allow(roles).to receive(:where).with(role: 'admin').and_return([])
    end
    context 'verify dependencies' do
      it { expect(User.new).to respond_to(:roles) }
    end
    context 'non admin' do
      it { expect(subject).to be false }
    end
    context 'admin' do
      let(:role) { double("role") }
      before { allow(roles).to receive(:where).with(role: 'admin').and_return([role]) }
      it { expect(subject).to be true }
    end
  end
end
