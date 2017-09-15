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
    sign_in user
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

  context 'orphan fileset with redirect_to' do
    let(:orphan_file_set) { create(:file_set, redirect_to: file_set.id) }
    it 'redirects to the approprite file_set in redirect_to' do
      get :show, params: { id: orphan_file_set.id }
      expect(response).to redirect_to Rails.application.routes.url_helpers.hyrax_file_set_path(file_set.id)
    end
  end
end
