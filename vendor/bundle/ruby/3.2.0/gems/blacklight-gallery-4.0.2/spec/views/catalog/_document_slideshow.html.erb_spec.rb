require 'spec_helper'

describe "catalog/_document_slideshow", :type => :view do
  let(:blacklight_config) do
    Blacklight::Configuration.new do |config|
      config.track_search_session = false
    end
  end

  let(:document) { stub_model(::SolrDocument) }

  before do
    allow(view).to receive_messages(
      blacklight_config: blacklight_config,
      documents: [document],
      document_index_view_type: 'slideshow',
      document_counter_with_offset: 1
    )
    allow(view).to receive(:current_search_session).and_return(nil)
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:search_state).and_return(Blacklight::SearchState.new({}, blacklight_config))
  end

  it 'has a modal' do
    render
    expect(rendered).to have_selector '#slideshow-modal'
    expect(rendered).to have_selector '[data-slide="prev"]'
    expect(rendered).to have_selector '[data-slide="next"]'
    expect(rendered).to have_selector '[data-slide-to="0"][data-toggle="modal"][data-target="#slideshow-modal"]'
  end
end
