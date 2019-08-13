# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScoreCatalogController, type: :controller do
  describe 'blacklight_config' do
    subject(:blacklight_config) { described_class.blacklight_config }

    it 'search_builder_class' do
      expect(blacklight_config.search_builder_class).to be ScoreSearchBuilder
    end
  end

  describe '#index' do
    context 'a public score' do
      let(:score) { create(:public_score) }

      before do
        get :index, params: { id: score.id }
      end

      it "is successful" do
        expect(response).to be_success
        expect(response).to render_template('score_catalog/index')
        expect(controller.instance_variable_get(:@presenter).class).to eq Hyrax::ScorePresenter
        expect(controller.instance_variable_get(:@ebook_download_presenter).class).to eq EBookDownloadPresenter
      end
    end

    context 'a draft score' do
      let(:score) { create(:score) }

      before do
        get :index, params: { id: score.id }
      end

      it "redirects to login" do
        expect(response).not_to be_success
        expect(response).not_to render_template('score_catalog/index')
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
