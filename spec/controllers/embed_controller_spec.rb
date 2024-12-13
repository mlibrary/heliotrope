# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbedController, type: :controller do
  describe '#noid' do
    it { expect(described_class.noid(nil)).to be nil }
    it { expect(described_class.noid(HandleNet::DOI_ORG_PREFIX + HandleNet::FULCRUM_HANDLE_PREFIX + 'invalidnoid')).to be nil }
    it { expect(described_class.noid(HandleNet::DOI_ORG_PREFIX + HandleNet::FULCRUM_HANDLE_PREFIX + 'validnoid')).to be nil }
    it { expect(described_class.noid(HandleNet::HANDLE_NET_PREFIX + HandleNet::FULCRUM_HANDLE_PREFIX + 'invalidnoid')).to be nil }
    it { expect(described_class.noid(HandleNet::HANDLE_NET_PREFIX + HandleNet::FULCRUM_HANDLE_PREFIX + 'validnoid')).to eq 'validnoid' }
    it { expect(described_class.noid(HandleNet::HANDLE_NET_PREFIX + HandleNet::FULCRUM_HANDLE_PREFIX + 'validnoid' + '?key=value')).to eq 'validnoid' }
    it { expect(described_class.noid(HandleNet::FULCRUM_HANDLE_PREFIX + 'invalidnoid')).to eq nil }
    it { expect(described_class.noid(HandleNet::FULCRUM_HANDLE_PREFIX + 'validnoid')).to eq 'validnoid' }
  end

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
        get :show, params: { hdl: hdl }
      end

      it { expect(response).to have_http_status(:unauthorized) }
    end

    context 'invalid presenter' do
      let(:hdl) { 'hdl' }
      let(:noid) { 'noid' }

      before do
        get :show, params: { hdl: hdl }
      end

      it { expect(response).to have_http_status(:unauthorized) }
    end

    context 'successful render' do
      let(:hdl) { 'hdl' }
      let(:noid) { 'noid' }
      let(:presenter) { object_double("presenter") }

      before do
        allow(described_class).to receive(:noid).with(hdl).and_return(noid)
        allow(Hyrax::PresenterFactory).to receive(:build_for).with(ids: [noid], presenter_class: Hyrax::FileSetPresenter, presenter_args: anything).and_return([presenter])
        get :show, params: { hdl: hdl }
      end

      it do
        expect(response).not_to have_http_status(:unauthorized)
        expect(response).to be_successful
        expect(response.headers.key?("X-Frame-Options")).to be false
        expect(response.headers.key?("Content-Security-Policy")).to be true
        expect(response.headers["Content-Security-Policy"]).to eq "frame-ancestors 'self' *"
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
                           press_tesim: press.subdomain,
                           member_ids_ssim: ['file_set_noid'])
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
      let(:keycard) { { dlpsInstitutionId: [dlps_institution_id.to_s] } }
      let(:institution) { create(:institution, identifier: dlps_institution_id.to_s) }
      let(:institution_affiliation) { create(:institution_affiliation, institution: institution, dlps_institution_id: dlps_institution_id, affiliation: 'member') }
      let(:dlps_institution_id) { 9999 }


      before do
        institution_affiliation
        ActiveFedora::SolrService.add([monograph.to_h, file_set.to_h])
        ActiveFedora::SolrService.commit
        allow_any_instance_of(Keycard::Request::Attributes).to receive(:all).and_return(keycard)
        allow(described_class).to receive(:noid).with(hdl).and_return('file_set_noid')
      end

      it "counts the file_set" do
        get :show, params: { hdl: hdl }
        expect(response).not_to have_http_status(:unauthorized)
        expect(response).to be_successful

        cr = CounterReport.last
        expect(cr.request).to eq 1
        expect(cr.investigation).to eq 1
        expect(cr.noid).to eq 'file_set_noid'
      end
    end
  end
end
