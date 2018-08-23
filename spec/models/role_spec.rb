# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Role, type: :model do
  subject { described_class.new(args) }

  describe 'with user_key' do
    let(:user) { create(:user) }
    let(:user_key) { user.email }
    let(:args) { { role: 'admin', user_key: user_key } }

    context "that doesn't point at a user" do
      let(:user_key) { 'bob' }

      it 'does not be valid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages).to eq(user: ["must exist"], user_key: ['User must sign up first.'])
      end
    end

    context 'that points at a user' do
      it 'is valid' do
        expect(subject).to be_valid
        expect(subject.errors.messages).to be_empty
      end
    end

    context 'that points at a user with an existing role' do
      before { described_class.create!(args) }

      it 'is valid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages).to eq(user_key: ['already a member of this press'])
      end
    end
  end
end
