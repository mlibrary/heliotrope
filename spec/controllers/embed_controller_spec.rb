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

    context 'counter report' do
      let(:press) { create(:press) }
      let(:hdl) { 'hdl' }
      let(:monograph) do
        ::SolrDocument.new(id: 'monograph_noid',
                           has_model_ssim: ['Monograph'],
                           title_tesim: ['_Red_'],
                           publisher_tesim: ["R Pub"],
                           isbn_tesim: ['111', '222'],
                           date_created_tesim: ['2000'],
                           press_tesim: press.subdomain)
      end
      let(:file_set) do
        ::SolrDocument.new(id: 'file_set_noid',
                           has_model_ssim: ['FileSet'],
                           title_tesim: ['An Image'],
                           monograph_id_ssim: ['monograph_noid'],
                           mime_type_ssi: 'image/jpg',
                           visibility_ssi: 'open',
                           read_access_group_ssim: ["public"])
      end
      let(:keycard) { { dlpsInstitutionId: [institution.identifier] } }
      let(:institution) { double('institution', identifier: '9999') }

      before do
        ActiveFedora::SolrService.add([monograph.to_h, file_set.to_h])
        ActiveFedora::SolrService.commit
        allow_any_instance_of(Keycard::Request::Attributes).to receive(:all).and_return(keycard)
        allow(Institution).to receive(:where).with(identifier: ['9999']).and_return([institution])
        allow(HandleService).to receive(:noid).with(hdl).and_return('file_set_noid')
      end

      it "counts the file_set" do
        get :show, params: { hdl: hdl }
        expect(response).not_to have_http_status(:unauthorized)
        expect(response).to be_success

        cr = CounterReport.last
        expect(cr.request).to eq 1
        expect(cr.investigation).to eq 1
        expect(cr.noid).to eq 'file_set_noid'
      end
    end
  end
end
