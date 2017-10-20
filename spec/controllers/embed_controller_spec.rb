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
        allow(HandleService).to receive(:object).with(hdl, 'test.host').and_return(nil)
        get :show, params: { hdl: hdl }
      end
      it { expect(response).to have_http_status(:unauthorized) }
    end

    context 'invalid presenter' do
      let(:hdl) { 'hdl' }
      let(:obj) { object_double("obj") }

      before do
        allow(HandleService).to receive(:object).with(hdl, 'test.host').and_return(obj)
        allow(obj).to receive(:id).and_return(0)
        get :show, params: { hdl: hdl }
      end
      it { expect(response).to have_http_status(:unauthorized) }
    end

    context 'successful render' do
      let(:hdl) { 'hdl' }
      let(:obj) { object_double("obj") }
      let(:presenter) { object_double("presenter") }

      before do
        allow(HandleService).to receive(:object).with(hdl, 'test.host').and_return(obj)
        allow(obj).to receive(:id).and_return(0)
        allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [obj.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: anything).and_return([presenter])
        get :show, params: { hdl: hdl }
      end
      it do
        expect(response).to_not have_http_status(:unauthorized)
        expect(response).to be_success
      end
    end

    context 'tombstone' do
      let(:hdl) { 'hdl' }

      before do
        allow(HandleService).to receive(:object).with(hdl, 'test.host').and_raise(Ldp::Gone)
        get :show, params: { hdl: hdl }
      end
      it do
        # The HTTP response status code 302 Found is a common way of performing URL redirection.
        expect(response).to have_http_status(:found)
        # raise CanCan::AccessDenied currently redirects to root_url
        expect(response.header["Location"]).to match "http://test.host/"
      end
    end
  end
end
