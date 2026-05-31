# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Gallery::SlideshowComponent, type: :component do
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
    )
  end

  let(:presenter) { Blacklight::IndexPresenter.new(document, view_context, blacklight_config) }

  before do
    allow(view_context).to receive(:current_search_session).and_return(nil)
    allow(view_context).to receive(:search_session).and_return({})
    allow(view_context).to receive(:blacklight_config).and_return(blacklight_config)
  end

  describe '#slideshow_tag' do
    subject { rendered }

    context 'with a slideshow method' do
      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.index.slideshow_method = :xyz
          config.track_search_session = false
        end
      end

      it 'calls the provided slideshow method' do
        expect(view_context).to receive_messages(xyz: 'some-slideshow')
        expect(rendered).to have_text 'some-slideshow'
      end

      it 'does not render an image if the method returns nothing' do
        expect(view_context).to receive_messages(xyz: nil)
        expect(rendered).not_to have_selector 'img'
      end
    end

    context 'with a slideshow field' do
      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.index.slideshow_field = :xyz 
          config.track_search_session = false
        end
      end
      let(:document) { SolrDocument.new({ xyz: 'http://example.com/some.jpg', id: 'x' }) }

      it { is_expected.to have_selector 'img[src="http://example.com/some.jpg"]' }

      context 'without data in the field' do
        let(:document) { SolrDocument.new({id: 'x'}) }

        it { is_expected.not_to have_selector 'img' }
      end
    end

    context 'with no view_config' do
      let(:blacklight_config) { Blacklight::Configuration.new.tap { |config| 
        config.track_search_session = false
      } }
      it { is_expected.not_to have_selector 'img' }
    end

    context 'falling back to a thumbnail' do
      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.index.thumbnail_field = :xyz 
          config.track_search_session = false
        end
      end
      let(:document) { SolrDocument.new({ xyz: 'http://example.com/thumb.jpg', id: 'x' }) }

      it { is_expected.to have_selector 'img[src="http://example.com/thumb.jpg"]' }
    end
  end
end
