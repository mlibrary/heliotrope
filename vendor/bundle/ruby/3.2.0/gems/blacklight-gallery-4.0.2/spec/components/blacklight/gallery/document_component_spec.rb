# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Gallery::DocumentComponent, type: :component do
  subject(:component) { described_class.new(document: document, presenter: presenter, **attr) }

  let(:attr) { {} }
  let(:view_context) { controller.view_context }
  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  let(:document) do
    SolrDocument.new(
      id: 'x',
      thumbnail_path_ss: 'http://example.com/image.jpg',
      title_tsim: 'This is my document title'
    )
  end

  let(:presenter) { Blacklight::IndexPresenter.new(document, view_context, blacklight_config) }

  let(:blacklight_config) do
    CatalogController.blacklight_config.deep_copy.tap do |config|
      config.track_search_session = false
      config.index.thumbnail_field = 'thumbnail_path_ss'
    end
  end

  before do
    allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view_context).to receive(:current_search_session).and_return(nil)
    allow(view_context).to receive(:search_session).and_return({})
    allow(view_context).to receive(:blacklight_config).and_return(blacklight_config)

    # dumb hack to get our stubbing into the thumbnail component
    allow(controller).to receive(:view_context).and_return(view_context)
  end

  it 'has a thumbnail and caption' do
    expect(rendered).to have_selector '.document-thumbnail img'
    expect(rendered).to have_selector '.caption', text: 'This is my document title'
  end
end
