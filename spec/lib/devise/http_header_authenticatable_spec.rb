# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Devise::Strategies::HttpHeaderAuthenticatable do
  subject { described_class.new(nil) }

  before { allow(subject).to receive(:request).and_return(request) } # rubocop:disable RSpec/SubjectStub

  describe '#valid?' do
    context 'in a production environment' do
      let(:production) { ActiveSupport::StringInquirer.new('production') }

      before { allow(Rails).to receive(:env).and_return(production) }

      context 'using REMOTE_USER' do
        let(:request) { double(headers: { 'REMOTE_USER' => 'abc123' }) }

        it { is_expected.not_to be_valid }
      end

      context 'using HTTP_REMOTE_USER' do
        let(:request) { double(headers: { 'HTTP_REMOTE_USER' => 'abc123' }) }

        it { is_expected.not_to be_valid }
      end

      context 'using HTTP_X_REMOTE_USER' do
        let(:request) { double(headers: { 'HTTP_X_REMOTE_USER' => 'abc123' }) }

        it { is_expected.to be_valid }
      end

      context 'using no header' do
        let(:request) { double(headers: {}) }

        it { is_expected.not_to be_valid }
      end
    end

    context 'in a development or test environment' do
      context 'using REMOTE_USER' do
        let(:request) { double(headers: { 'REMOTE_USER' => 'abc123' }) }

        it { is_expected.not_to be_valid }
      end

      context 'using HTTP_REMOTE_USER' do
        let(:request) { double(headers: { 'HTTP_REMOTE_USER' => 'abc123' }) }

        it { is_expected.not_to be_valid }
      end

      context 'using HTTP_X_REMOTE_USER' do
        let(:request) { double(headers: { 'HTTP_X_REMOTE_USER' => 'abc123' }) }

        it { is_expected.to be_valid }
      end

      context 'using no header' do
        let(:request) { double(headers: {}) }

        it { is_expected.not_to be_valid }
      end
    end
  end

  describe 'authenticate!' do
    let(:request) { double(headers: header) }

    context 'without HTTP_X_REMOTE_USER header' do
      let(:header) { {} }

      it 'fails' do
        expect(subject).not_to be_valid
        expect(subject.authenticate!).to eq(:failure)
      end
    end

    context 'with HTTP_X_REMOTE_USER header' do
      let(:header) { { 'HTTP_X_REMOTE_USER' => remote_user } }

      context 'with a blank user' do
        let(:remote_user) { '' }

        it 'fails' do
          expect(subject).not_to be_valid
          expect(subject.authenticate!).to eq(:failure)
        end
      end

      ['umich.edu', 'friends.com'].each do |domain|
        let(:email) { "name@#{domain}" }
        let(:remote_user) { domain == 'umich.edu' ? 'name' : email }

        context "with user name@#{domain}" do
          context 'when a new user' do
            before { allow(User).to receive(:find_by).with(user_key: user.user_key).and_return(nil) }

            context 'when create_user_on_login is enabled' do
              let(:user) { User.new(user_key: email) }

              it 'allocates new user' do
                allow(Rails.configuration).to receive(:create_user_on_login).and_return(true)
                expect(User).to receive(:new).with(user_key: user.user_key).once.and_return(user)
                expect(Guest).not_to receive(:new).with(user_key: user.user_key)
                expect(subject).to be_valid
                expect(subject.authenticate!).to eq(:success)
              end
            end

            context 'when create_user_on_login is disabled' do
              let(:user) { User.guest(user_key: email) }

              it 'allocates new guest' do
                allow(Rails.configuration).to receive(:create_user_on_login).and_return(false)
                expect(User).not_to receive(:new).with(user_key: user.user_key)
                expect(Guest).to receive(:new).with(user_key: user.user_key).once.and_return(user)
                expect(subject).to be_valid
                expect(subject.authenticate!).to eq(:success)
              end
            end
          end

          context 'when an existing user' do
            let(:user) { create(:user, user_key: email) }

            before { allow(User).to receive(:find_by).with(user_key: user.user_key).and_return(user) }

            it 'accepts the existing user' do
              expect(User).not_to receive(:new).with(user_key: user.user_key)
              expect(Guest).not_to receive(:new).with(user_key: user.user_key)
              expect(subject).to be_valid
              expect(subject.authenticate!).to eq(:success)
            end
          end
        end
      end
    end
  end
end
