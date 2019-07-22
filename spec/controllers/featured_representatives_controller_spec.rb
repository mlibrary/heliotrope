# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeaturedRepresentativesController, type: :controller do
  let(:monograph) { create(:monograph) }
  let(:file_set)  { create(:file_set) }

  context "as a platform_admin" do
    before { sign_in user }

    let(:user) { create(:platform_admin) }

    describe '#save' do
      before do
        allow(UnpackJob).to receive_messages(perform_later: nil, perform_now: nil)
        post :save, params: { monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub' }
      end

      after { FeaturedRepresentative.destroy_all }

      it "saves the featured_representative" do
        expect(FeaturedRepresentative.all.count).to be 1
      end
    end

    describe '#delete' do
      let(:fr) { create(:featured_representative, monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

      before do
        delete :delete, params: { id: fr.id, monograph_id: monograph.id }
      end

      it "deletes the featured_representative" do
        expect(FeaturedRepresentative.all.count).to be 0
      end
    end
  end

  context "as a press_admin" do
    before { sign_in user }

    let(:my_press) { create(:press) }
    let(:user) { create(:press_admin, press: my_press) }

    describe '#save' do
      before do
        allow(UnpackJob).to receive_messages(perform_later: nil, perform_now: nil)
        post :save, params: { monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub' }
      end

      after { FeaturedRepresentative.destroy_all }

      it "saves the featured_representative" do
        expect(FeaturedRepresentative.all.count).to be 1
      end
    end

    describe '#delete' do
      let(:fr) { create(:featured_representative, monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

      before do
        delete :delete, params: { id: fr.id, monograph_id: monograph.id }
      end

      it "deletes the featured_representative" do
        expect(FeaturedRepresentative.all.count).to be 0
      end
    end
  end
end
