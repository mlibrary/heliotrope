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
        allow(HandleService).to receive(:object).with(hdl).and_return(nil)
        get :show, hdl: hdl
      end
      it { expect(response).to have_http_status(:unauthorized) }
    end

    context 'invalid presenter' do
      let(:hdl) { 'hdl' }
      let(:obj) { double("obj") }
      before do
        allow(HandleService).to receive(:object).with(hdl).and_return(obj)
        allow(obj).to receive(:id).and_return(0)
        get :show, hdl: hdl
      end
      it { expect(response).to have_http_status(:unauthorized) }
    end

    context 'successful render' do
      let(:hdl) { 'hdl' }
      let(:obj) { double("obj") }
      let(:presenter) { double("presenter") }
      before do
        allow(HandleService).to receive(:object).with(hdl).and_return(obj)
        allow(obj).to receive(:id).and_return(0)
        allow(CurationConcerns::PresenterFactory).to receive(:build_presenters).with([obj.id], CurationConcerns::FileSetPresenter, anything).and_return([presenter])
        get :show, hdl: hdl
      end
      it { expect(response).to_not have_http_status(:unauthorized) }
      it { expect(response).to be_success }
    end
  end
end
