# frozen_string_literal: true

require 'rails_helper'

describe Hyrax::FileSetsController do
  let(:user) { create(:platform_admin) }
  let(:press) { create(:press) }
  let(:monograph) { create(:monograph, user: user, press: press.subdomain) }
  let(:file_set) { create(:file_set) }

  before do
    monograph.ordered_members << file_set
    monograph.save!
    file_set.save!
    cosign_sign_in user
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
end
