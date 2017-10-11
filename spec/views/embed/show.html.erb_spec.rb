# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "embed/show.html.erb", type: :view do
  let(:mock_file) { Hydra::PCDM::File.new }
  let(:file_set) do
    FileSet.new(id: 'a0s1d2f3g', title: ['A Title'], creator: ['Pants, Mr Smarty']) do |f|
      f.apply_depositor_metadata('user@example.com')
    end
  end
  let(:file_set_doc) { SolrDocument.new(file_set.to_solr) }
  let(:file_set_presenter) { Hyrax::FileSetPresenter.new(file_set_doc, nil) }

  context 'image' do
    before do
      allow(mock_file).to receive(:mime_type).and_return('image/tiff')
      allow(file_set).to receive(:resource_type).and_return(['Book', 'Other'])
      allow(file_set).to receive(:original_file).and_return(mock_file)
      assign(:presenter, file_set_presenter)
      render
    end
    it {
      expect(rendered).to_not have_tag('maincontent')
      expect(rendered).to_not have_tag('asset')
      expect(rendered).to have_tag('figure')
      # logo links back to the Fulcrum asset page through the handle
      expect(rendered).to have_css("img[src*='fulcrum-white-50px']", count: 1)
      expect(rendered).to have_link(nil,
                                    href: file_set_presenter.citable_link,
                                    title: file_set_presenter.embed_fulcrum_logo_title)
    }
  end

  context 'video' do
    before do
      allow(mock_file).to receive(:mime_type).and_return('video/mp4')
      allow(file_set).to receive(:resource_type).and_return(['Movie', 'Other'])
      allow(file_set).to receive(:original_file).and_return(mock_file)
      assign(:presenter, file_set_presenter)
      render
    end
    it {
      expect(rendered).to_not have_tag('maincontent')
      expect(rendered).to_not have_tag('asset')
      expect(rendered).to have_tag('figure')
      # logo links back to the Fulcrum asset page through the handle
      expect(rendered).to have_css("img[src*='fulcrum-white-50px']", count: 1)
      expect(rendered).to have_link(nil,
                                    href: file_set_presenter.citable_link,
                                    title: file_set_presenter.embed_fulcrum_logo_title)
    }
  end
end
