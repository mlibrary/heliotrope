require 'rails_helper'

describe MonographCatalogController do
  describe '#index' do
    context 'when not a monograph id' do
      before { get :index, id: 'not_a_monograph_id' }
      it 'then expect response unauthorized' do
        expect(response).to be_unauthorized
      end
    end

    context 'when a monograph id' do
      let(:press) { build(:press) }
      let(:user) { create(:platform_admin) }
      let(:monograph) { create(:monograph, user: user, press: press.subdomain) }
      before { get :index, id: monograph.id }
      context 'then expect' do
        it 'response success' do
          expect(response).to be_success
        end
        it 'curation concern to be the monograph' do
          expect(controller.instance_variable_get(:@curation_concern)).to eq monograph
        end
        it 'monograph presenter is a monograph presenter class' do
          expect(controller.instance_variable_get(:@monograph_presenter).class).to eq CurationConcerns::MonographPresenter
        end
        it 'mongraph presenter has the monograph' do
          expect(controller.instance_variable_get(:@monograph_presenter).title.first).to eq monograph.title.first
        end
      end
    end
  end # #index
end
