require 'spec_helper'

describe "catalog/openseadragon_default" do
  let(:document) { SolrDocument.new }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:p) { "catalog/openseadragon_default" }

  before do
    allow(view).to receive_messages(blacklight_config: blacklight_config, openseadragon_picture_tag: "<img />")
    allow(document).to receive_messages(to_openseadragon: [])
  end

  it "should render the openseadragon container" do
    render partial: p, locals: { document: document }
    expect(rendered).to have_selector ".openseadragon-container"
  end

  it "should support passing a container class" do
    render partial: p, locals: { document: document, osd_container_class: "custom-container" }
    expect(rendered).to have_selector ".custom-container"
  end
end
