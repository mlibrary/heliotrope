# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  describe '#new' do
    subject { get :new }

    context 'user signed in' do
      before { allow_any_instance_of(described_class).to receive(:user_signed_in?).and_return(true) }

      it do
        is_expected.to redirect_to root_path(locale: 'en')
        expect(cookies[:fulcrum_signed_in_static]).not_to be nil
      end

      context 'stored location for user' do
        before { allow_any_instance_of(SessionsController).to receive(:stored_location_for).with(:user).and_return('http://return_to_me') }

        it { is_expected.to redirect_to 'http://return_to_me' }
      end
    end

    context 'user not signed in' do
      before { allow_any_instance_of(described_class).to receive(:user_signed_in?).and_return(false) }

      it { is_expected.to redirect_to new_authentications_path }
    end
  end

  describe '#destroy' do
    subject { get :destroy }

    before do
      cookies[:fulcrum_signed_in_static] = true
      allow_any_instance_of(described_class).to receive(:user_signed_in?).and_return(true)
    end

    it do
      expect(ENV).to receive(:[]=).with('FAKE_HTTP_X_REMOTE_USER', '(null)')
      is_expected.to redirect_to root_url
      expect(cookies[:fulcrum_signed_in_static]).to be nil
    end
  end

  describe '#discovery_feed' do
    it 'gets full discovery feed' do
      get :discovery_feed
      expect(response).to be_success
      expect { JSON.parse response.body }.not_to raise_error
      expect(JSON.parse(response.body).size).to be > 1
    end
  end

  describe '#discovery_feed/id' do
    let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
    it 'gets parameterized discovery feed' do
      component = Component.create!(handle: HandleService.path(file_set.id))
      institution = Institution.create!(identifier: 'UM', name: 'Name', site: 'Site',
                                        login: 'Login', entity_id: 'https://shibboleth.umich.edu/idp/shibboleth')
      product = Product.create!(identifier: 'product', name: 'name', purchase: 'purchase')
      product.components << component
      grouping = Grouping.create!(identifier: 'grouping')
      product.lessees << grouping.lessee
      lessee = Lessee.find_by(identifier: 'UM')
      grouping.lessees << lessee
      institution.save!
      lessee.save!
      grouping.save!
      product.save!
      get :discovery_feed, params: { id: file_set.id }
      expect(response).to have_http_status(:success)
      expect { JSON.parse response.body }.not_to raise_error
      expect(JSON.parse(response.body).size).to be(1)
      expect(JSON.parse(response.body)[0]['entityID']).to eq('https://shibboleth.umich.edu/idp/shibboleth')
    end
    it 'gets full discovery feed if given bogus id' do
      get :discovery_feed, params: { id: 'bogus_id' }
      expect(response).to have_http_status(:success)
      expect { JSON.parse response.body }.not_to raise_error
      expect(JSON.parse(response.body).size).to be > 1
    end
  end
end
