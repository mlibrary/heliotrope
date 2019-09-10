# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Monograph Catalog", type: :request do
  describe '#representative' do
    let(:monograph) { create(:monograph) }
    let(:file_set) { create(:file_set) }

    before { allow(monograph).to receive(:save!).and_call_original }

    context 'anonymous' do
      describe "POST /concern/monographs/:id/representitive" do
        it do
          post monograph_catalog_representative_path(monograph), params: { representative_id: file_set.id }
          expect(response).to redirect_to(monograph_catalog_url(monograph))
          expect(monograph).not_to have_received(:save!)
          monograph.reload
          expect(monograph.thumbnail).not_to eq(file_set)
          expect(monograph.representative).not_to eq(file_set)
        end
      end
    end

    context 'user' do
      before { sign_in(current_user) }

      context 'unauthorized' do
        let(:current_user) { create(:user) }

        describe "POST /concern/monographs/:id/representitive" do
          it do
            post monograph_catalog_representative_path(monograph), params: { representative_id: file_set.id }
            expect(response).to redirect_to(monograph_catalog_url(monograph))
            expect(monograph).not_to have_received(:save!)
            monograph.reload
            expect(monograph.thumbnail).not_to eq(file_set)
            expect(monograph.representative).not_to eq(file_set)
          end
        end
      end

      context 'authorized' do
        let(:current_user) { create(:platform_admin) }

        describe "POST /concern/monographs/:id/representitive" do
          it do
            post monograph_catalog_representative_path(monograph), params: { representative_id: file_set.id }
            expect(response).to redirect_to(monograph_catalog_url(monograph))
            expect(monograph).not_to have_received(:save!)
            monograph.reload
            expect(monograph.thumbnail).to eq(file_set)
            expect(monograph.representative).to eq(file_set)
          end
        end
      end
    end
  end
end
