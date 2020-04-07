# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModelTreesController, type: :controller do
  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # GrantsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  # let(:current_actor) { instance_double(Anonymous, 'current_actor') }
  let(:noid) { 'validnoid' }

  describe "GET #show" do
    let(:entity) { instance_double(Sighrax::Entity, 'entity') }
    let(:press) { instance_double(Press, 'press') }
    let(:hyrax_presenter) { instance_double(Hyrax::Presenter, 'hyrax_presenter') }
    let(:model_tree) { instance_double(ModelTree, 'model_tree') }

    before do
      allow(Sighrax).to receive(:from_noid).with(noid).and_return(entity)
      allow(Sighrax).to receive(:press).with(entity).and_return(press)
      allow(Sighrax).to receive(:hyrax_presenter).with(entity).and_return(hyrax_presenter)
      allow(ModelTree).to receive(:from_entity).with(entity).and_return(model_tree)
    end

    it "returns a success response" do
      get :show, params: { id: noid }, session: valid_session
      expect(response).to be_success
      expect(response).to render_template(:show)
    end
  end

  context 'Model Tree' do
    let(:model_tree) { instance_double(ModelTree, 'model_tree') }

    before do
      allow(ModelTree).to receive(:from_noid).with(noid).and_return(model_tree)
      allow(model_tree).to receive(:kind=).with(kind)
      allow(model_tree).to receive(:save)
    end

    describe "POST #kind" do
      let(:kind) { 'kind' }

      it "redirects to show page" do
        post :kind, params: { id: noid, kind: kind }, session: valid_session
        expect(model_tree).to have_received(:kind=).with(kind)
        expect(model_tree).to have_received(:save)
        expect(response).to be_redirect
        expect(response).to redirect_to(model_tree_path)
      end
    end

    describe "DELETE #unkind" do
      let(:kind) { nil }

      it "redirects to show page" do
        delete :unkind, params: { id: noid }, session: valid_session
        expect(model_tree).to have_received(:kind=).with(kind)
        expect(model_tree).to have_received(:save)
        expect(response).to be_redirect
        expect(response).to redirect_to(model_tree_path)
      end
    end
  end

  context 'Model Tree Service' do
    let(:model_tree_service) { instance_double(ModelTreeService, 'model_tree_service') }

    before { allow(ModelTreeService).to receive(:new).and_return(model_tree_service) }

    describe "POST #link" do
      let(:child_noid) { 'child6789' }

      before { allow(model_tree_service).to receive(:link).with(noid, child_noid) }

      it "redirects to show page" do
        post :link, params: { id: noid, child_id: child_noid }, session: valid_session
        expect(model_tree_service).to have_received(:link).with(noid, child_noid)
        expect(response).to be_redirect
        expect(response).to redirect_to(model_tree_path)
      end
    end

    describe "DELETE #unlink" do
      before { allow(model_tree_service).to receive(:unlink_parent).with(noid) }

      it "redirects to show page" do
        delete :unlink, params: { id: noid }, session: valid_session
        expect(model_tree_service).to have_received(:unlink_parent).with(noid)
        expect(response).to be_redirect
        expect(response).to redirect_to(model_tree_path)
      end
    end
  end
end
