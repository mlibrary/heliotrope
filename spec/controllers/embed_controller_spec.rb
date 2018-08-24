# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbedController, type: :controller do
  describe "GET #show" do
    context 'missing param' do
      before do
        get :show
      end

      it { expect(response).to have_http_status(:unauthorized) }
    end

    context 'invalid handle' do
      let(:hdl) { 'hdl' }

      before do
        allow(HandleService).to receive(:noid).with(hdl).and_return(nil)
        get :show, params: { hdl: hdl }
      end

      it { expect(response).to have_http_status(:unauthorized) }
    end

    context 'invalid presenter' do
      let(:hdl) { 'hdl' }
      let(:noid) { 'noid' }

      before do
        allow(HandleService).to receive(:noid).with(hdl).and_return(noid)
        get :show, params: { hdl: hdl }
      end

      it { expect(response).to have_http_status(:unauthorized) }
    end

    context 'successful render' do
      let(:hdl) { 'hdl' }
      let(:noid) { 'noid' }
      let(:presenter) { object_double("presenter") }

      before do
        allow(HandleService).to receive(:noid).with(hdl).and_return(noid)
        allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [noid], presenter_class: Hyrax::FileSetPresenter, presenter_args: anything).and_return([presenter])
        get :show, params: { hdl: hdl }
      end

      it do
        expect(response).not_to have_http_status(:unauthorized)
        expect(response).to be_success
      end
    end
  end
end
