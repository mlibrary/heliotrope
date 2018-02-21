# frozen_string_literal: true

require 'rails_helper'

describe MonographCatalogController do
  describe 'blacklight_config' do
    blacklight_config = described_class.blacklight_config

    context 'number of records per page' do
      it 'defaults to 20' do
        expect(blacklight_config.default_per_page).to eq 20
      end
    end

    context 'facet_fields' do
      expected_fields = %w[based_near section_title keywords creator_full_name content_type resource_type search_year exclusive_to_platform contributor]
      expected_facet_fields = expected_fields.map { |field| described_class.solr_name(field, :facetable) }

      it 'has expected facet fields' do
        expect(blacklight_config.facet_fields).to include(*expected_facet_fields)
      end

      context 'facet field content_type' do
        expected_facet_field_content_type = described_class.solr_name('content_type', :facetable)
        facet_field_content_type = blacklight_config.facet_fields[expected_facet_field_content_type]

        it 'has label' do
          expect(facet_field_content_type.label).to eq("Content")
        end
        it 'show false' do
          expect(facet_field_content_type.show).to be_falsey
        end
      end
      context 'facet field resource_type' do
        expected_facet_field_resource_type = described_class.solr_name('resource_type', :facetable)
        expected_facet_field_content_type = described_class.solr_name('content_type', :facetable)
        facet_field_resource_type = blacklight_config.facet_fields[expected_facet_field_resource_type]

        it 'has label' do
          expect(facet_field_resource_type.label).to eq("Format")
        end
        it 'has pivot' do
          expect(facet_field_resource_type.pivot).to_not be_nil
        end
        it 'pivot has expected facet field names' do
          expect(facet_field_resource_type.pivot).to eq([expected_facet_field_resource_type, expected_facet_field_content_type])
        end
      end
      context 'facet field contributor' do
        expected_facet_field = described_class.solr_name('contributor', :facetable)
        facet_field = blacklight_config.facet_fields[expected_facet_field]

        it 'has label' do
          expect(facet_field.label).to eq("Contributor")
        end
        it 'show false' do
          expect(facet_field.show).to be_falsey
        end
      end
    end
  end # blacklight_config

  describe '#index' do
    context 'no monograph exists with provided id' do
      context 'id never existed' do
        before { get :index, params: { id: 'not_a_monograph_id' } }
        it 'response is not successful' do
          expect(response).to_not be_success
          expect(response).to_not render_template('monograph_catalog/index')
        end
        it 'shows 404 page' do
          expect(response.status).to equal 404
          expect(response.body).to have_title("404 - The page you were looking for doesn't exist")
        end
      end
      context 'deleted/tombstoned id' do
        let(:monograph) { create(:monograph) }
        before do
          monograph.destroy!
          get :index, params: { id: monograph.id }
        end
        it 'response is not successful' do
          expect(response).to_not be_success
          expect(response).to_not render_template('monograph_catalog/index')
        end
        it 'shows 404 page' do
          expect(response.status).to equal 404
          expect(response.body).to have_title("404 - The page you were looking for doesn't exist")
        end
      end
    end
    context 'when a monograph with the id exists' do
      context 'when a monograph is open/public' do
        let(:monograph) { create(:public_monograph) }
        before do
          get :index, params: { id: monograph.id }
        end
        it 'response is successful' do
          expect(response).to be_success
          expect(response).to render_template('monograph_catalog/index')
        end
        it 'curation concern to be the monograph' do
          expect(controller.instance_variable_get(:@curation_concern)).to eq monograph
        end
        it 'monograph presenter is a monograph presenter class' do
          expect(controller.instance_variable_get(:@monograph_presenter).class).to eq Hyrax::MonographPresenter
        end
        it 'mongraph presenter has the monograph' do
          expect(controller.instance_variable_get(:@monograph_presenter).solr_document.id).to eq monograph.id
        end
      end
      context 'when a monograph is draft/private' do
        context 'no user logged in' do
          let(:monograph) { create(:private_monograph) }
          before do
            get :index, params: { id: monograph.id }
          end
          it 'response is not successful' do
            expect(response).to_not be_success
            expect(response).to_not render_template('monograph_catalog/index')
          end
          it 'redirects to login page' do
            expect(response).to redirect_to(new_user_session_path)
          end
        end
        context 'logged-in read user (depositor)' do
          let(:user) { create(:user) }
          let(:monograph) { create(:private_monograph, user: user) }
          before do
            cosign_sign_in user
            get :index, params: { id: monograph.id }
          end
          it 'response is successful' do
            expect(response).to be_success
            expect(response).to render_template('monograph_catalog/index')
          end
          it 'curation concern to be the monograph' do
            expect(controller.instance_variable_get(:@curation_concern)).to eq monograph
          end
          it 'monograph presenter is a monograph presenter class' do
            expect(controller.instance_variable_get(:@monograph_presenter).class).to eq Hyrax::MonographPresenter
          end
          it 'mongraph presenter has the monograph' do
            expect(controller.instance_variable_get(:@monograph_presenter).solr_document.id).to eq monograph.id
          end
        end
      end
    end
  end # #index
end
