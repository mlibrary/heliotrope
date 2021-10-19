# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'hyrax/file_sets/_media' do
  let(:file_set) {
    build(:file_set,
          id: 'fileset_id',
          title: ['Things'],
          caption: ['Stuff'],
          has_model: ['FileSet'],
          external_resource_url: 'http://things.at/stuff')
  }
  let(:file_set_doc) { SolrDocument.new(file_set.to_solr) }
  let(:ability) { double('ability') }
  let(:request) { double('request') }
  let(:file_set_presenter) { Hyrax::FileSetPresenter.new(file_set_doc, ability, request) }
  let(:allow_download) { nil }
  let(:resource_download_operation_allowed) { false }

  before do
    assign(:presenter, file_set_presenter)
    assign(:resource_download_operation_allowed, resource_download_operation_allowed)
  end

  context 'with an external_resource' do
    it 'has the external resource url' do
      render
      expect(rendered).to match('<a class="btn btn-default btn-lg" href="http://things.at/stuff" title=')
    end
  end

  context 'with an epub' do
    let(:alt_text) { double('alt_text') }
    let(:present) { double('present') }

    before do
      allow(alt_text).to receive(:first).and_return('alt_text')
      allow(file_set_presenter).to receive(:alt_text).and_return(alt_text)
      allow(file_set_presenter).to receive(:external_resource_url).and_return('')
      allow(file_set_presenter).to receive(:image?).and_return(false)
      allow(file_set_presenter).to receive(:epub?).and_return(true)
      allow(present).to receive(:present?).and_return(false)
      allow(file_set_presenter).to receive(:closed_captions).and_return(present)
      allow(file_set_presenter).to receive(:transcript).and_return(present)
      allow(file_set_presenter).to receive(:translation).and_return(present)
      allow(file_set_presenter).to receive(:visual_descriptions).and_return(present)
    end

    it do
      stub_template("hyrax/file_sets/media_display/_epub.html.erb" => "epub")
      render
      expect(rendered).to match(/epub/)
    end
  end

  context 'download button' do
    before do
      allow(FileSet).to receive(:find).with('fileset_id').and_return(file_set)
      render
    end

    context 'has a download link when resource download operation allowed' do
      let(:resource_download_operation_allowed) { true }

      it { expect(rendered).to have_link('Download') }
    end

    context 'has no download link when resource download operation not allowed' do
      let(:resource_download_operation_allowed) { false }

      it { expect(rendered).not_to have_link('Download') }
    end
  end
end
