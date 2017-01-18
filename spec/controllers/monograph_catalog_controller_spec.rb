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
      expected_fields = %w(based_near section_title keywords creator_full_name content_type resource_type search_year exclusive_to_platform)
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
    end
  end # blacklight_config

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
          expect(controller.instance_variable_get(:@monograph_presenter).solr_document.id).to eq monograph.id
        end
      end
    end
  end # #index
end
