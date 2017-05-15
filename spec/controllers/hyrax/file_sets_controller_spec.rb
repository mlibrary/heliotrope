# frozen_string_literal: true

require 'rails_helper'

describe Hyrax::FileSetsController do
  context 'visibility' do
    let(:controller) { described_class.new }
    let(:params) { { file_set: { visibility_during_embargo: "restricted",
                                 embargo_release_date: "2020-01-01",
                                 visibility_after_embargo: "open",
                                 visibility_during_lease: "open",
                                 lease_expiration_date: "2020-01-01",
                                 visibility_after_lease: "restricted" } } }

    describe "when visibility is embargo" do
      before do
        params[:file_set][:visibility] = 'embargo'
        controller.params = params
        controller.fix_visibility
      end
      it "has no visibility_during_lease" do
        expect(controller.params[:file_set][:visibility_during_lease]).to be nil
      end
      it "has a visibiltiy of restricted" do
        expect(controller.params[:file_set][:visibility]).to eq('restricted')
      end
    end

    describe "when visibiltiy is lease" do
      before do
        params[:file_set][:visibility] = 'lease'
        controller.params = params
        controller.fix_visibility
      end
      it "has no visibility_during_embargo" do
        expect(controller.params[:file_set][:visibility_during_embargo]).to be nil
      end
      it "has a visibility of public" do
        expect(controller.params[:file_set][:visibility]).to eq('open')
      end
    end

    describe "when visibility is open" do
      before do
        params[:file_set][:visibility] = 'open'
        controller.params = params
        controller.fix_visibility
      end
      it "has no visibility_during_embargo" do
        expect(controller.params[:file_set][:visibility_during_embargo]).to be nil
      end
      it "has no visibility_during_lease" do
        expect(controller.params[:file_set][:visibility_during_lease]).to be nil
      end
      it "has a visibility of public" do
        expect(controller.params[:file_set][:visibility]).to eq('open')
      end
    end

    describe "when visibility is private" do
      before do
        params[:file_set][:visibility] = 'restricted'
        controller.params = params
        controller.fix_visibility
      end
      it "has no visibility_during_embargo" do
        expect(controller.params[:file_set][:visibility_during_embargo]).to be nil
      end
      it "has no visibility_during_lease" do
        expect(controller.params[:file_set][:visibility_during_lease]).to be nil
      end
      it "has a visibility of restricted" do
        expect(controller.params[:file_set][:visibility]).to eq('restricted')
      end
    end

    describe "when visibility is authenticated" do
      before do
        params[:file_set][:visibility] = 'authenticated'
        controller.params = params
        controller.fix_visibility
      end
      it "has no visibility_during_embargo" do
        expect(controller.params[:file_set][:visibility_during_embargo]).to be nil
      end
      it "has no visibility_during_lease" do
        expect(controller.params[:file_set][:visibility_during_lease]).to be nil
      end
      it "has a visibility of authenticated" do
        expect(controller.params[:file_set][:visibility]).to eq('authenticated')
      end
    end
  end

  context 'tombstone' do
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
end
