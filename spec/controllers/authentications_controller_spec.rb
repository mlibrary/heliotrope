# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthenticationsController, type: :controller do
  describe '#show' do
    let(:actor) { Anonymous.new({}) }

    before do
      allow(controller).to receive(:current_actor).and_return(actor)
      allow(RecacheInCommonMetadataJob).to receive(:perform_later).and_return(true)
    end

    context 'no params' do
      subject { get :show }

      before { allow(AuthenticationPresenter).to receive(:for).with(actor, nil, nil, nil).and_call_original }

      it do
        allow(File).to receive(:exists?).with(RecacheInCommonMetadataJob::JSON_FILE).and_return(false)
        is_expected.to redirect_to default_login_path
        expect(RecacheInCommonMetadataJob).to have_received(:perform_later)
        expect(AuthenticationPresenter).to have_received(:for).with(actor, nil, nil, nil)
        expect(controller.instance_variable_get(:@presenter).publisher?).to be false
        expect(controller.instance_variable_get(:@presenter).monograph?).to be false
      end
    end

    context ':press param' do
      subject { get :show, { params: { press: press.subdomain } } }

      let(:press) { create(:press) }

      before { allow(AuthenticationPresenter).to receive(:for).with(actor, press.subdomain, nil, nil).and_call_original }

      it do
        allow(File).to receive(:exists?).with(RecacheInCommonMetadataJob::JSON_FILE).and_return(false)
        is_expected.to have_http_status(:ok)
        expect(RecacheInCommonMetadataJob).to have_received(:perform_later)
        expect(AuthenticationPresenter).to have_received(:for).with(actor, press.subdomain, nil, nil)
        expect(controller.instance_variable_get(:@presenter).publisher?).to be true
        expect(controller.instance_variable_get(:@presenter).monograph?).to be false
      end
    end

    context 'monograph :id param' do
      subject { get :show, { params: { id: monograph.id } } }

      let(:monograph) { create(:monograph) }

      before { allow(AuthenticationPresenter).to receive(:for).with(actor, nil, monograph.id, nil).and_call_original }

      it do
        is_expected.to have_http_status(:ok)
        allow(File).to receive(:exists?).with(RecacheInCommonMetadataJob::JSON_FILE).and_return(false)
        expect(RecacheInCommonMetadataJob).to have_received(:perform_later)
        expect(AuthenticationPresenter).to have_received(:for).with(actor, nil, monograph.id, nil)
        expect(controller.instance_variable_get(:@presenter).publisher?).to be true
        expect(controller.instance_variable_get(:@presenter).monograph?).to be true
      end
    end

    context 'file_set :id param' do
      subject { get :show, { params: { id: file_set.id } } }

      let(:monograph) do
        m = create(:monograph)
        m.ordered_members << file_set
        m.save!
        file_set.save!
        m
      end
      let(:file_set) { create(:file_set) }

      before { allow(AuthenticationPresenter).to receive(:for).with(actor, nil, file_set.id, nil).and_call_original }

      it do
        monograph
        allow(File).to receive(:exists?).with(RecacheInCommonMetadataJob::JSON_FILE).and_return(false)
        is_expected.to have_http_status(:ok)
        expect(RecacheInCommonMetadataJob).to have_received(:perform_later)
        expect(AuthenticationPresenter).to have_received(:for).with(actor, nil, file_set.id, nil)
        expect(controller.instance_variable_get(:@presenter).publisher?).to be true
        expect(controller.instance_variable_get(:@presenter).monograph?).to be true
      end
    end

    context 'optional filter param' do
      subject { get :show, { params: { filter: true } } }

      before { allow(AuthenticationPresenter).to receive(:for).with(actor, nil, nil, "true").and_call_original }

      it do
        is_expected.to redirect_to default_login_path
        expect(AuthenticationPresenter).to have_received(:for).with(actor, nil, nil, "true")
        expect(controller.instance_variable_get(:@presenter).publisher?).to be false
      end
    end
  end

  describe '#new' do
    subject { get :new }

    it { is_expected.to render_template :new }
  end

  describe '#create' do
    subject { post :create, params: { authentication: { email: 'wolverine@umich.edu' } } }

    it do
      expect(ENV).to receive(:[]=).with('FAKE_HTTP_X_REMOTE_USER', 'wolverine@umich.edu')
      is_expected.to redirect_to new_user_session_path
    end
  end

  describe '#destroy' do
    subject { get :destroy }

    it { is_expected.to redirect_to root_url }

    context 'stored location for user' do
      before { allow_any_instance_of(described_class).to receive(:stored_location_for).with(:user).and_return('http://return_to_me') }

      it { is_expected.to redirect_to 'http://return_to_me' }
    end
  end
end
