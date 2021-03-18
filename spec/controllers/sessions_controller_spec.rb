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
        before { allow_any_instance_of(described_class).to receive(:stored_location_for).with(:user).and_return('http://return_to_me') }

        it { is_expected.to redirect_to 'http://return_to_me' }
      end
    end

    context 'user not signed in' do
      before { allow_any_instance_of(described_class).to receive(:user_signed_in?).and_return(false) }

      it { is_expected.to redirect_to new_authentications_path }
    end
  end

  describe '#shib_session' do
    subject { get :shib_session, params: { resource: resource } }

    let(:resource) { prefix + path }
    let(:prefix) { '' }
    let(:path) { '' }
    let(:target) { '/' + path }

    before { allow_any_instance_of(described_class).to receive(:authenticate_user!) }

    it { is_expected.to redirect_to target }

    context 'path' do
      let(:path) { 'concern/noid' }

      it { is_expected.to redirect_to target }

      context 'root' do
        let(:prefix) { '/' }

        it { is_expected.to redirect_to target }
      end

      context 'http' do
        let(:prefix) { 'HtTp://anything you want between the slashes/' }

        it { is_expected.to redirect_to target }
      end

      context 'https' do
        let(:prefix) { 'HtTpS://everything up to the slash/' }

        it { is_expected.to redirect_to target }
      end
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

  context 'discovery feed' do
    let(:job) { instance_double(RecacheInCommonMetadataJob, 'job', download_xml: true, parse_xml: true, load_json: feed) }
    let(:feed) do
      JSON.parse(
        <<~DISCO_FEED
          [
            {"entityID":"https://shibboleth.umich.edu/idp/shibboleth","Descriptions":[{"value":"The University of Michigan","lang":"en"}],"DisplayNames":[{"value":"University of Michigan","lang":"en"}],"InformationURLs":[{"value":"http://www.umich.edu/","lang":"en"}],"Logos":[{"value":"https://shibboleth.umich.edu/images/StackedBlockM-InC.png","height":"150","width":"300","lang":"en"}],"PrivacyStatementURLs":[{"value":"https://documentation.its.umich.edu/node/262/","lang":"en"}]},
            {"entityID":"urn:mace:incommon:msu.edu","Descriptions":[],"DisplayNames":[{"value":"Michigan State University","lang":"en"}],"InformationURLs":[],"Logos":[{"value":"https://brand.msu.edu/_files/images/masthead-helmet-green.png","height":"34","width":"298","lang":"en"}],"PrivacyStatementURLs":[{"value":"https://msu.edu/privacy/","lang":"en"}]}
          ]
        DISCO_FEED
      )
    end
    let(:institution1) { Greensub::Institution.create(identifier: '1', name: 'University of Michigan', site: 'Site', login: 'Login', entity_id: 'https://shibboleth.umich.edu/idp/shibboleth') }
    let(:institution2) { Greensub::Institution.create(identifier: '2', name: 'Michigan State University', site: 'Site', login: 'Login', entity_id: 'urn:mace:incommon:msu.edu') }

    before { allow(RecacheInCommonMetadataJob).to receive(:new).and_return(job) }

    describe '#discovery_feed' do
      it 'gets full discovery feed' do
        get :discovery_feed
        expect(response).to be_successful
        expect { JSON.parse response.body }.not_to raise_error
        expect(JSON.parse(response.body).size).to eq(2)
        expect(JSON.parse(response.body)[0]['entityID']).to eq('https://shibboleth.umich.edu/idp/shibboleth')
        expect(JSON.parse(response.body)[1]['entityID']).to eq('urn:mace:incommon:msu.edu')
      end
    end

    describe '#discovery_feed/id' do
      let(:monograph) do
        create(:public_monograph) do |m|
          m.ordered_members << file_set
          m.save!
          file_set.save!
          m
        end
      end
      let(:file_set) { create(:public_file_set) }

      before { clear_grants_table }

      it 'gets parameterized discovery feed' do
        m = Sighrax.from_noid(monograph.id)
        component = Greensub::Component.create!(identifier: m.resource_token, name: m.title, noid: m.noid)
        product = Greensub::Product.create!(identifier: 'product', name: 'name', purchase: 'purchase')
        product.components << component
        product.save!
        institution1.update_product_license(product)
        get :discovery_feed, params: { id: file_set.id }
        expect(response).to have_http_status(:success)
        expect { JSON.parse response.body }.not_to raise_error
        expect(JSON.parse(response.body).size).to eq(1)
        expect(JSON.parse(response.body)[0]['entityID']).to eq('https://shibboleth.umich.edu/idp/shibboleth')
      end

      it 'gets empty discovery feed if given bogus id' do
        get :discovery_feed, params: { id: 'bogus_id' }
        expect(response).to have_http_status(:success)
        expect { JSON.parse response.body }.not_to raise_error
        expect(JSON.parse(response.body).size).to eq(0)
      end
    end
  end
end
