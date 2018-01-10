# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeaturedRepresentativesController, type: :controller do
  let(:monograph) { create(:monograph) }
  let(:file_set)  { create(:file_set) }
  let(:user) { create(:platform_admin) }

  context "as a platform_admin" do
    # TODO: allow press admins to set/unset FeaturedRepresentatives
    before { sign_in user }

    describe '#save' do
      before { post :save, params: { monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub' } }
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
