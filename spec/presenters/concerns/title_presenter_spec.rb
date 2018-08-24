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

  let(:solr_document) { SolrDocument.new(title_tesim: [markdown_title]) }
  let(:presenter) { self.class::Presenter.new(solr_document) }

  describe 'Presenter' do
    subject { presenter }

    let(:markdown_title) { double("markdown title") }

    it 'includes TitlePresenter' do
      is_expected.to be_a described_class
    end
  end

  describe '#page_title' do
    subject { presenter.page_title }

    let(:expected_markdown_title_as_text) { 'Title' }

    context 'empty array' do
      let(:markdown_title) { nil }

      it 'translates markdown to text' do
        is_expected.to eq expected_markdown_title_as_text
      end
    end

    context 'empty string' do
      let(:markdown_title) { '' }

      it 'translates markdown to text' do
        is_expected.to eq expected_markdown_title_as_text
      end
    end

    context '__Markdown Title__' do
      let(:markdown_title) { '__Markdown Title__' }
      let(:expected_markdown_title_as_text) { 'Markdown Title' }

      it 'translates markdown to text' do
        is_expected.to eq expected_markdown_title_as_text
      end
    end
  end

  describe '#title' do
    subject { presenter.title }

    let(:expected_markdown_title_as_html_safe) { 'Title'.html_safe }

    context 'empty array' do
      let(:markdown_title) { nil }

      it 'translates markdown to safe html' do
        is_expected.to eq expected_markdown_title_as_html_safe
        is_expected.to be_a ActiveSupport::SafeBuffer
      end
    end

    context 'empty string' do
      let(:markdown_title) { '' }

      it 'translates markdown to safe html' do
        is_expected.to eq expected_markdown_title_as_html_safe
        is_expected.to be_a ActiveSupport::SafeBuffer
      end
    end

    context '__Markdown Title__' do
      let(:markdown_title) { '__Markdown Title__' }
      let(:expected_markdown_title_as_html_safe) { '<strong>Markdown Title</strong>'.html_safe }

      it 'translates markdown to safe html' do
        is_expected.to eq expected_markdown_title_as_html_safe
        is_expected.to be_a ActiveSupport::SafeBuffer
      end
    end
  end
end
