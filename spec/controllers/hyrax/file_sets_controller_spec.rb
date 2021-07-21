# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::FileSetsController, type: :controller do
  let(:user) { create(:platform_admin) }
  let(:press) { create(:press) }
  let(:monograph) { create(:monograph, user: user, press: press.subdomain) }
  let(:file_set) { create(:file_set) }

  before do
    monograph.ordered_members << file_set
    monograph.save!
    file_set.save!
    sign_in user
  end

  describe "#destroy" do
    before { stub_out_redis }

    context "featured_representative file_set and cached table of contents" do
      before do
        FeaturedRepresentative.create(work_id: monograph.id, file_set_id: file_set.id, kind: 'epub')
        EbookTableOfContentsCache.create(noid: file_set.id, toc: [{ title: "A", depth: 1, cfi: "/6/2[Chapter01]!/4/1:0" }].to_json)
      end

      it "deletes the featured_representative and the file_set" do
        expect do
          delete :destroy, params: { id: file_set }
        end.to change { FeaturedRepresentative.all.count }.from(1).to(0)
        expect(EbookTableOfContentsCache.find_by(noid: file_set.id)).to be nil
        expect(FileSet.all.count).to be 0
      end
    end

    context "not a featured_representative and not cached table of contents" do
      it "just deletes the file_set" do
        delete :destroy, params: { id: file_set }
        expect(FileSet.all.count).to be 0
      end
    end
  end

  context 'tombstone' do
    context 'file set created' do
      before do
        get :show, params: { parent_id: monograph.id, id: file_set.id }
      end

      it do
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
        expect(response).to render_template("hyrax/file_sets/show")
      end
    end

    context 'file set deleted' do
      before do
        file_set.destroy!
        get :show, params: { parent_id: monograph.id, id: file_set.id }
      end

      it do
        # The HTTP response status code 302 Found is a common way of performing URL redirection.
        expect(response).to have_http_status(:found)
        # raise CanCan::AccessDenied currently redirects to root_url
        expect(response.header["Location"]).to match "http://test.host/"
      end
    end
  end

  context 'redirection with redirect_to' do
    context 'orphan FileSet redirects to FileSet with monograph parent' do
      let(:orphan_file_set) { create(:file_set, redirect_to: file_set.id) }

      it 'redirects to the approprite file_set in redirect_to' do
        get :show, params: { id: orphan_file_set.id }
        expect(response).to redirect_to Rails.application.routes.url_helpers.hyrax_file_set_path(file_set.id)
      end
    end

    context 'redirect_to doesn\'t contain a FileSet NOID' do
      let(:root_redirect_fileset) { create(:file_set, redirect_to: 'home page') }

      it 'redirects to root' do
        get :show, params: { id: root_redirect_fileset.id }
        expect(response).to redirect_to '/'
      end
    end
  end

  context 'redirection of non-editors from cover/representative file_set show pages' do
    let(:epub_monograph) {
      create(:public_monograph,
             user: user,
             press: press.subdomain,
             representative_id: cover.id,
             thumbnail_id: thumbnail.id)
    }
    let(:epub) { create(:public_file_set) }
    let(:cover) { create(:public_file_set) }
    let(:thumbnail) { create(:public_file_set) }
    let(:fre) { create(:featured_representative, work_id: epub_monograph.id, file_set_id: epub.id, kind: 'epub') }

    before do
      epub_monograph.ordered_members = [cover, thumbnail, epub]
      epub_monograph.save!
      [cover, thumbnail, epub].map(&:save!)
    end

    context 'editor tries to load show page of a cover/representative file_set' do
      it 'representative loads its show page' do
        get :show, params: { id: fre.file_set_id }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
        expect(response).to render_template("hyrax/file_sets/show")
      end

      it 'cover loads its show page' do
        get :show, params: { id: cover.id }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
        expect(response).to render_template("hyrax/file_sets/show")
      end

      it 'thumbnail loads its show page' do
        get :show, params: { id: thumbnail.id }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
        expect(response).to render_template("hyrax/file_sets/show")
      end
    end

    context 'non-editor tries to load show page of a cover/representative file_set' do
      let(:non_editor) { create(:user) }

      before do
        sign_in non_editor
      end

      it 'representative redirects to the monograph show page' do
        get :show, params: { id: fre.file_set_id }
        expect(response).to redirect_to Rails.application.routes.url_helpers.monograph_catalog_path(epub_monograph.id)
      end

      it 'cover redirects to the monograph show page' do
        get :show, params: { id: cover.id }
        expect(response).to redirect_to Rails.application.routes.url_helpers.monograph_catalog_path(epub_monograph.id)
      end

      it 'thumbnail redirects to the monograph show page' do
        get :show, params: { id: thumbnail.id }
        expect(response).to redirect_to Rails.application.routes.url_helpers.monograph_catalog_path(epub_monograph.id)
      end
    end
  end

  context 'update the thumbnail' do
    let(:thumbnail_path) { File.join(fixture_path, 'csv', 'shipwreck.jpg') }
    let(:thumbnail_deriv_path) { Hyrax::DerivativePath.derivative_path_for_reference(file_set.id, 'thumbnail') }
    let(:file) { fixture_file_upload('/csv/shipwreck.jpg', 'image/jpg') }

    it 'copies the updated file to the thumbnail derivative path' do
      # no derivatives for this FileSet yet
      expect(Hyrax::DerivativePath.derivatives_for_reference(file_set).count).to eq 0
      expect(File).not_to exist(thumbnail_deriv_path)

      post :update, params: { id: file_set, user_thumbnail: { custom_thumbnail: file } }

      # now the "uploaded" thumbnail is in place
      expect(Hyrax::DerivativePath.derivatives_for_reference(file_set).count).to eq 1
      expect(File).to exist(thumbnail_deriv_path)
      expect(FileUtils.compare_file(thumbnail_path, thumbnail_deriv_path)).to be_truthy
    end
    after do
      FileUtils.rm_rf(Hyrax.config.derivatives_path)
    end
  end

  context 'setting the `thumbnail_path_ss` Solr value' do
    # note: querying the changed Solr values results in intermittent timing errors, so just verifying SolrService.add()
    let(:file_set_doc_default) { file_set.to_solr.merge(thumbnail_path_ss: default_thumbnail_path) }
    let(:default_thumbnail_path) { ActionController::Base.helpers.image_path('default.png') }

    let(:file_set_doc_derivative) { file_set.to_solr.merge(thumbnail_path_ss: thumbnail_derivative_path) }
    let(:thumbnail_derivative_path) { Hyrax::Engine.routes.url_helpers.download_path(file_set.id, file: 'thumbnail') }

    it 'sets it to the Hyrax default thumbnail path' do
      expect(ActiveFedora::SolrService).to receive(:add).with(file_set_doc_default, softCommit: true)
      post :update, params: { id: file_set, user_thumbnail: { use_default: '1' } }
    end
    it 'sets it to the thumbnail derivative path' do
      expect(ActiveFedora::SolrService).to receive(:add).with(file_set_doc_derivative, softCommit: true)
      post :update, params: { id: file_set, user_thumbnail: { use_default: '0' } }
    end
  end

  context "counter report counts from the show page" do
    let(:keycard) { { dlpsInstitutionId: [dlps_institution_id.to_s] } }
    let(:institution) { create(:institution, identifier: dlps_institution_id.to_s) } # TODO: Prefix with '#'
    let(:institution_affiliation) { create(:institution_affiliation, institution: institution, dlps_institution_id: dlps_institution_id, affiliation: 'member') }
    let(:dlps_institution_id) { 9999 }

    before do
      institution_affiliation
      allow_any_instance_of(Keycard::Request::Attributes).to receive(:all).and_return(keycard)
      file_set.read_groups << "public"
      file_set.visibility = "open"
    end

    context "a multimedia file_set" do
      before do
        Hydra::Works::AddFileToFileSet.call(file_set, File.open(fixture_path + '/csv/shipwreck.jpg'), :original_file)
        file_set.save!
      end

      it "counts as an investigation and a request" do
        get :show, params: { id: file_set.id }
        cr = CounterReport.last
        expect(cr.request).to eq 1
        expect(cr.investigation).to eq 1
      end
    end

    context "a non-multimedia file_set" do
      before do
        Hydra::Works::AddFileToFileSet.call(file_set, File.open(fixture_path + '/stuff.xlsx'), :original_file)
        file_set.save!
      end

      it "counts only as an investigation" do
        get :show, params: { id: file_set.id }
        cr = CounterReport.last
        expect(cr.request).to eq nil
        expect(cr.investigation).to eq 1
      end
    end
  end
end
