# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MonographCatalogController, type: :controller do
  describe 'blacklight_config' do
    subject(:blacklight_config) { described_class.blacklight_config }

    it 'search_builder_class' do
      expect(blacklight_config.search_builder_class).to be MonographSearchBuilder
    end

    it 'default_per_page' do
      expect(blacklight_config.default_per_page).to eq 20
    end

    describe 'facet_fields' do
      subject(:facet_fields) { blacklight_config.facet_fields }

      let(:ordered_keys) {
        [
          described_class.solr_name('based_near', :facetable),
          described_class.solr_name('press_name', :symbol),
          described_class.solr_name('generic_type', :facetable),
          described_class.solr_name('section_title', :facetable),
          described_class.solr_name('keywords', :facetable),
          described_class.solr_name('creator', :facetable),
          described_class.solr_name('content_type', :facetable),
          described_class.solr_name('resource_type', :facetable),
          described_class.solr_name('search_year', :facetable),
          described_class.solr_name('exclusive_to_platform', :facetable),
          described_class.solr_name('contributor', :facetable),
          described_class.solr_name('primary_creator_role', :facetable)
        ]
      }

      it 'ordered keys' do
        expect(facet_fields.keys).to eq(ordered_keys)
      end

      describe 'content_type' do
        subject(:facet_field) { facet_fields[described_class.solr_name('content_type', :facetable)] }

        it 'label' do
          expect(facet_field.label).to eq("Content")
        end
        it 'show' do
          expect(facet_field.show).to be false
        end
      end

      describe 'resource_type' do
        subject(:facet_field) { facet_fields[resource_type_facetable] }

        let(:resource_type_facetable) { described_class.solr_name('resource_type', :facetable) }
        let(:content_type_facetable) {  described_class.solr_name('content_type', :facetable) }

        it 'label' do
          expect(facet_field.label).to eq("Format")
        end
        it 'pivot' do
          expect(facet_field.pivot).not_to be_nil
        end
        it 'pivot keys' do
          expect(facet_field.pivot).to eq([resource_type_facetable, content_type_facetable])
        end
      end

      describe 'contributor' do
        subject(:facet_field) { facet_fields[described_class.solr_name('contributor', :facetable)] }

        it 'label' do
          expect(facet_field.label).to eq("Contributor")
        end
        it 'show' do
          expect(facet_field.show).to be false
        end
      end
    end
  end

  describe '#index' do
    context 'no monograph exists with provided id' do
      context 'id never existed' do
        before { get :index, params: { id: 'not_a_monograph_id' } }

        it 'response is not successful' do
          expect(response).not_to be_success
          expect(response).not_to render_template('monograph_catalog/index')
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
          expect(response).not_to be_success
          expect(response).not_to render_template('monograph_catalog/index')
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
            expect(response).not_to be_success
            expect(response).not_to render_template('monograph_catalog/index')
          end
          it 'redirects to login page' do
            expect(response).to redirect_to(new_user_session_path)
          end
        end

        context 'logged-in read user (depositor)' do
          let(:user) { create(:user) }
          let(:monograph) { create(:private_monograph, user: user) }

          before do
            sign_in user
            get :index, params: { id: monograph.id }
          end

          it 'response is successful' do
            expect(response).to be_success
            expect(response).to render_template('monograph_catalog/index')
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
  end
end
