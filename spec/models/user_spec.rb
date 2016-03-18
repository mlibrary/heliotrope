require 'rails_helper'

describe User do
  describe '#user_key' do
    let(:user) { described_class.new(email: 'foo@example.com') }
    subject { user.user_key }
    it { is_expected.to eq 'foo@example.com' }
  end

  describe '#presses' do
    let(:press1) { create(:press) }
    let(:press2) { create(:press) }
    let!(:press3) { create(:press) }
    let(:user) { create(:user) }
    before do
      create(:role, resource: press1, user: user, role: 'admin')
      create(:role, resource: press2, user: user, role: 'admin')
    end
    subject { user.presses }
    it { is_expected.to eq [press1, press2] }
  end

  describe '#platform_admin?' do
    subject { user.platform_admin? }

    context "when a platform admin" do
      let(:user) { create(:platform_admin) }
      it { is_expected.to be true }
    end

    context "when a press admin" do
      let(:user) { create(:press_admin) }
      it { is_expected.to be false }
    end
  end
end
