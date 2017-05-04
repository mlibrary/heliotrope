# frozen_string_literal: true

require 'rails_helper'

class Presenter
  include TitlePresenter
  attr_reader :solr_document

  def initialize(solr_document)
    @solr_document = solr_document
  end
end

describe TitlePresenter do
  let(:markdown_title) { '__Markdown Title__' }
  let(:expected_markdown_title_as_text) { 'Markdown Title' }
  let(:expected_markdown_title_as_html_safe) { '<strong>Markdown Title</strong>'.html_safe }
  let(:solr_document) { SolrDocument.new(title_tesim: [markdown_title]) }
  let(:presenter) { Presenter.new(solr_document) }

  describe 'Presenter' do
    it 'includes TitlePresenter' do
      expect(presenter).to be_a described_class
    end
  end

  describe '#page_title' do
    it 'translates markdown to text' do
      expect(presenter.page_title).to eq expected_markdown_title_as_text
    end
  end

  describe '#title' do
    it 'translates markdown to html' do
      expect(presenter.title).to eq expected_markdown_title_as_html_safe
    end
    it 'returns safe html' do
      expect(presenter.title).to be_a ActiveSupport::SafeBuffer
    end
  end
end
