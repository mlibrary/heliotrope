require 'rails_helper'

describe User do
  describe 'user_key' do
    let(:user) { described_class.new(email: 'foo@example.com') }
    subject { user.user_key }
    it { is_expected.to eq 'foo@example.com' }
  end
end
