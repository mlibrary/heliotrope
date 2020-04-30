# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogHelper do
  describe '#current_sort_field' do
    subject { helper.current_sort_field }

    let(:blacklight_config) { Blacklight::Configuration.new }
    let(:blacklight_configuration_context) { Blacklight::Configuration::Context.new(controller) }
    let(:blacklight_solr_response) { instance_double(Blacklight::Solr::Response, 'blacklight_solr_response') }
    let(:sort) { nil }

    before do
      controller.class.include Blacklight::Controller
      controller.class.include Blacklight::Catalog
      assign(:response, blacklight_solr_response)
      allow(blacklight_solr_response).to receive(:sort).and_return(sort)
      allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
      allow(controller).to receive(:blacklight_configuration_context).and_return(blacklight_configuration_context)
    end

    context 'browse' do
      before do
        blacklight_config.add_sort_field 'date_uploaded desc', sort: "#{Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)} desc", label: "Date Added (Newest First)"
        blacklight_config.add_sort_field 'author asc', sort: "#{Solrizer.solr_name('creator_full_name', :sortable)} asc", label: "Author (A-Z)"
        blacklight_config.add_sort_field 'author desc', sort: "#{Solrizer.solr_name('creator_full_name', :sortable)} desc", label: "Author (Z-A)"
        blacklight_config.add_sort_field 'year desc', sort: "#{Solrizer.solr_name('date_created', :sortable)} desc, #{Solrizer.solr_name('date_published', :sortable)} desc", label: "Publication Date (Newest First)"
        blacklight_config.add_sort_field 'year asc', sort: "#{Solrizer.solr_name('date_created', :sortable)} asc, #{Solrizer.solr_name('date_published', :sortable)} asc", label: "Publication Date (Oldest First)"
        blacklight_config.add_sort_field 'title asc', sort: "#{Solrizer.solr_name('title', :sortable)} asc", label: "Title (A-Z)"
        blacklight_config.add_sort_field 'title desc', sort: "#{Solrizer.solr_name('title', :sortable)} desc", label: "Title (Z-A)"
      end

      it ('default sort') { expect(subject.key).to eq 'date_uploaded desc' }

      context 'response sort year desc a.k.a. press configured default sort' do
        let(:sort) { 'date_created_si desc, date_published_si desc' }

        it ('response sort') { expect(subject.key).to eq 'year desc' }

        context 'params sort year asc a.k.a. user preference sort' do
          before { params[:sort] = 'year asc' }

          it ('response sort') { expect(subject.key).to eq 'year desc' } # You would think it would be 'year asc', perhaps this is a blacklight bug.
        end
      end

      context 'response sort relevance a.k.a. search' do
        let(:sort) { 'score desc, date_uploaded_dtsi desc' }

        it ('default sort') { expect(subject.key).to eq 'date_uploaded desc' }
      end

      context 'params sort year asc a.k.a. user preference sort' do
        before { params[:sort] = 'year asc' }

        it ('params sort') { expect(subject.key).to eq 'year asc' }
      end

      context 'params sort relevance a.k.a. a.k.a. user preference same as search' do
        before { params[:sort] = 'relevance' }

        it ('default sort') { expect(subject.key).to eq 'date_uploaded desc' }
      end
    end

    context 'search' do
      before do
        blacklight_config.add_sort_field 'relevance', sort: "score desc, #{Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)} desc", label: "Relevance"
        blacklight_config.add_sort_field 'author asc', sort: "#{Solrizer.solr_name('creator_full_name', :sortable)} asc", label: "Author (A-Z)"
        blacklight_config.add_sort_field 'author desc', sort: "#{Solrizer.solr_name('creator_full_name', :sortable)} desc", label: "Author (Z-A)"
        blacklight_config.add_sort_field 'year desc', sort: "#{Solrizer.solr_name('date_created', :sortable)} desc, #{Solrizer.solr_name('date_published', :sortable)} desc", label: "Publication Date (Newest First)"
        blacklight_config.add_sort_field 'year asc', sort: "#{Solrizer.solr_name('date_created', :sortable)} asc, #{Solrizer.solr_name('date_published', :sortable)} asc", label: "Publication Date (Oldest First)"
        blacklight_config.add_sort_field 'title asc', sort: "#{Solrizer.solr_name('title', :sortable)} asc", label: "Title (A-Z)"
        blacklight_config.add_sort_field 'title desc', sort: "#{Solrizer.solr_name('title', :sortable)} desc", label: "Title (Z-A)"
      end

      it ('default sort') { expect(subject.key).to eq 'relevance' }

      context 'response sort year desc a.k.a. press configured default sort' do
        let(:sort) { 'date_created_si desc, date_published_si desc' }

        it ('default sort') { expect(subject.key).to eq 'relevance' }

        context 'params sort year asc a.k.a. user preference sort' do
          before { params[:sort] = 'year asc' }

          it ('params sort') { expect(subject.key).to eq 'year asc' }
        end
      end

      context 'response sort date_uploaded desc a.k.a. browse' do
        let(:sort) { 'date_uploaded_dtsi desc' }

        it ('default sort') { expect(subject.key).to eq 'relevance' }
      end

      context 'params sort year asc a.k.a. user preference sort' do
        before { params[:sort] = 'year asc' }

        it ('params sort') { expect(subject.key).to eq 'year asc' }
      end

      context 'params sort date_uploaded desc a.k.a. user preference same as browse' do
        before { params[:sort] = 'date_uploaded desc' }

        it ('default sort') { expect(subject.key).to eq 'relevance' }
      end
    end
  end
end
