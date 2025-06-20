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
          described_class.solr_name('keyword', :facetable),
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
        let(:content_type_facetable) { described_class.solr_name('content_type', :facetable) }

        it 'label' do
          expect(facet_field.label).to eq("Format")
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
    context 'Monograph with ebook representative' do
      let(:monograph) { create(:public_monograph) }
      let(:counter_service) { double('counter_service') }
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub_multi_rendition.epub'))) }
      let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
        allow(CounterService).to receive(:from).and_return(counter_service)
        allow(counter_service).to receive(:count)
        # The "controller" here is the instance of MonographCatalogController created by rspec
        allow(controller).to receive(:send_irus_analytics_investigation)
      end

      context 'triggers COUNTER, local and IRUS' do
        it 'counts' do
          get :index, params: { id: monograph.id }
          expect(counter_service).to have_received(:count)
          expect(controller).to have_received(:send_irus_analytics_investigation)
        end
      end

      context 'reader_links_display' do
        context 'draft ebook FeaturedRepresentative FileSet, e.g. a "Forthcoming Monograph"' do
          it "doesn't show the read button" do
            get :index, params: { id: monograph.id }
            expect(assigns(:reader_links_display)).to eq :not_shown
          end

          context 'with a valid share link' do
            let(:valid_share_token) do
              JsonWebToken.encode(data: monograph.id, exp: Time.now.to_i + 28 * 24 * 3600)
            end

            it "shows the read button, _linked_" do
              get :index, params: { id: monograph.id, share: valid_share_token }
              expect(assigns(:reader_links_display)).to eq :linked
            end
          end
        end

        context 'public ebook FeaturedRepresentative FileSet' do
          let(:file_set) { create(:public_file_set, content: File.open(File.join(fixture_path, 'fake_epub_multi_rendition.epub'))) }

          it "shows the read button" do
            get :index, params: { id: monograph.id }
            expect(assigns(:reader_links_display)).to eq :linked
          end

          context '`ee` press' do
            let(:monograph) { create(:public_monograph, press: 'ee') }

            it "does not show the read button" do
              get :index, params: { id: monograph.id }
              expect(assigns(:reader_links_display)).to eq :not_shown
            end
          end

          context 'tombstoned Monograph' do
            let(:monograph) { create(:public_monograph, tombstone: 'yes') }

            it "does not show the read button" do
              get :index, params: { id: monograph.id }
              expect(assigns(:reader_links_display)).to eq :not_shown
            end
          end
        end
      end
    end

    context 'no monograph exists with provided id' do
      context 'id never existed' do
        before { get :index, params: { id: 'not_a_monograph_id' } }

        it 'response is not successful' do
          expect(response).not_to be_successful
          expect(response).not_to render_template('monograph_catalog/index')
        end
        it 'shows 404 page' do
          expect(response.status).to be 404
          expect(response.body).to have_title("404 - The page you were looking for doesn't exist")
        end
        it 'does not set show_read_button' do
          expect(assigns(:show_read_button)).to eq nil
        end
      end

      context 'deleted/tombstoned id' do
        let(:monograph) { create(:monograph) }

        before do
          monograph.destroy!
          get :index, params: { id: monograph.id }
        end

        after do
          ActiveFedora::Cleaner.clean! # Sweep away tombstone a.k.a. LDP::Gone
        end

        it 'response is not successful' do
          expect(response).not_to be_successful
          expect(response).not_to render_template('monograph_catalog/index')
        end
        it 'shows 404 page' do
          expect(response.status).to be 404
          expect(response.body).to have_title("404 - The page you were looking for doesn't exist")
        end
        it 'does not set show_read_button' do
          expect(assigns(:show_read_button)).to eq nil
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
          expect(response).to be_successful
          expect(response).to render_template('monograph_catalog/index')
        end
        it 'monograph presenter is a monograph presenter class' do
          expect(controller.instance_variable_get(:@monograph_presenter).class).to eq Hyrax::MonographPresenter
        end
        it 'mongraph presenter has the monograph' do
          expect(controller.instance_variable_get(:@monograph_presenter).solr_document.id).to eq monograph.id
        end
        it 'sets search_ongoing to false' do
          expect(assigns(:search_ongoing)).to eq false
        end
        it 'sets show_read_button to false' do
          expect(assigns(:reader_links_display)).to eq :not_shown
        end
      end

      context 'when a monograph is draft/private' do
        context 'no user logged in' do
          let(:monograph) { create(:private_monograph) }

          before do
            get :index, params: { id: monograph.id }
          end

          it 'response is not successful' do
            expect(response).not_to be_successful
            expect(response).not_to render_template('monograph_catalog/index')
          end
          it 'does not set show_read_button' do
            expect(assigns(:reader_links_display)).to eq nil
          end
          it 'redirects to login page' do
            expect(response).to redirect_to(new_user_session_path)
          end

          context 'with a valid share link' do
            let(:valid_share_token) do
              JsonWebToken.encode(data: monograph.id, exp: Time.now.to_i + 28 * 24 * 3600)
            end

            before do
              get :index, params: { id: monograph.id, share: valid_share_token }
            end

            it 'response is successful' do
              expect(response).to be_successful
              expect(response).to render_template('monograph_catalog/index')
            end
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
            expect(response).to be_successful
            expect(response).to render_template('monograph_catalog/index')
            expect(controller.instance_variable_get(:@auth)).to be_an_instance_of(Auth)
            expect(controller.instance_variable_get(:@auth).return_location).to eq Rails.application.routes.url_helpers.monograph_catalog_path(monograph.id)
          end
          it 'monograph presenter is a monograph presenter class' do
            expect(controller.instance_variable_get(:@monograph_presenter).class).to eq Hyrax::MonographPresenter
          end
          it 'mongraph presenter has the monograph' do
            expect(controller.instance_variable_get(:@monograph_presenter).solr_document.id).to eq monograph.id
          end
          it 'sets search_ongoing to false' do
            expect(assigns(:search_ongoing)).to eq false
          end
          it 'sets reader_links_display to `:not_shown`' do
            expect(assigns(:reader_links_display)).to eq :not_shown
          end

          context 'textbox search term in play' do
            before { get :index, params: { id: monograph.id, q: 'blah' } }

            it 'sets search_ongoing to true' do
              expect(assigns(:search_ongoing)).to eq true
            end
            it 'sets reader_links_display to `:not_shown`' do
              expect(assigns(:reader_links_display)).to eq :not_shown
            end
          end
        end
      end
    end
  end
end
