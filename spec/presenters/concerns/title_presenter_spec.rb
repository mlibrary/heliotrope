# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TitlePresenter do
  class self::Presenter # rubocop:disable Style/ClassAndModuleChildren
    include TitlePresenter
    attr_reader :solr_document

    def initialize(solr_document)
      @solr_document = solr_document
    end
  end

  let(:solr_document) { SolrDocument.new(title_tesim: [input_title]) }
  let(:presenter) { self.class::Presenter.new(solr_document) }

  describe 'Presenter' do
    subject { presenter }

    let(:input_title) { double("markdown title") }

    it 'includes TitlePresenter' do
      is_expected.to be_a described_class
    end
  end

  describe '#page_title' do
    subject { presenter.page_title }

    let(:expected_output_title_as_text) { 'Title' }

    context 'empty array' do
      let(:input_title) { nil }

      it 'translates markdown to text' do
        is_expected.to eq expected_output_title_as_text
      end
    end

    context 'empty string' do
      let(:input_title) { '' }

      it 'translates markdown to text' do
        is_expected.to eq expected_output_title_as_text
      end
    end

    context '__Markdown Title__' do
      let(:input_title) { '__Markdown Title__' }
      let(:expected_output_title_as_text) { 'Markdown Title' }

      it 'translates markdown to text' do
        is_expected.to eq expected_output_title_as_text
      end
    end
  end

  describe '#title' do
    subject { presenter.title }

    let(:expected_output_title_as_html_safe) { 'Title'.html_safe }

    context 'empty array' do
      let(:input_title) { nil }

      it 'translates markdown to safe html' do
        is_expected.to eq expected_output_title_as_html_safe
        is_expected.to be_a ActiveSupport::SafeBuffer
      end
    end

    context 'empty string' do
      let(:input_title) { '' }

      it 'translates markdown to safe html' do
        is_expected.to eq expected_output_title_as_html_safe
        is_expected.to be_a ActiveSupport::SafeBuffer
      end
    end

    context '__Markdown Title__' do
      let(:input_title) { '__Markdown Title__' }
      let(:expected_output_title_as_html_safe) { '<strong>Markdown Title</strong>'.html_safe }

      it 'translates markdown to safe html' do
        is_expected.to eq expected_output_title_as_html_safe
        is_expected.to be_a ActiveSupport::SafeBuffer
      end
    end
  end

  describe '#embed_code_title' do
    subject { presenter.embed_code_title }

    let(:default_title) { 'Title' }
    let(:expected_output_title_with_html_entities) { 'A &#39;Title&#39; with Single Quotes' }

    context 'empty array' do
      let(:input_title) { nil }

      it 'translates markdown to safe html' do
        is_expected.to eq default_title
      end
    end

    context 'empty string' do
      let(:input_title) { '' }

      it 'translates markdown to safe html' do
        is_expected.to eq default_title
      end
    end

    context 'title with single quotes' do
      let(:input_title) { "A 'Title' with Single Quotes" }

      it 'translates markdown to safe html' do
        is_expected.to eq expected_output_title_with_html_entities
      end
    end
  end

  describe '#to_s' do
    subject { monograph_presenter.to_s }

    let(:monograph_presenter) { Hyrax::MonographPresenter.new(solr_document, nil) }
    let(:input_title) { 'A Title with __Markdown__ and some <em>HTML Tags</em>: Bad for CitationsBehavior' }
    let(:markup_and_tag_free_title) { 'A Title with Markdown and some HTML Tags: Bad for CitationsBehavior' }

    it 'strips Markdown and HTML tags' do
      is_expected.to eq markup_and_tag_free_title
    end
  end

  describe '#url_title' do
    subject { presenter.url_title }

    let(:input_title) { '#hashtag: A subtitle and _markdown_ and <em>HTML Tags</em> and stuff' }
    let(:urlable_markup_free_title) { '%23hashtag%3A+A+subtitle+and+markdown+and+HTML+Tags+and+stuff' }

    it 'CGI escapes and strips Markdown and HTML tags' do
      is_expected.to eq urlable_markup_free_title
    end
  end
end
