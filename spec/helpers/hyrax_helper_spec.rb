# frozen_string_literal: true

require 'rails_helper'

describe HyraxHelper do
  describe "#default_document_index_view_type" do
    context "with PressCatalogController default" do
      let(:press) { Press.new(default_list_view: false) }
      before do
        allow(controller).to receive(:is_a?).with(PressCatalogController).and_return(true)
      end
      it 'returns press catalog default gallery view' do
        @press = press
        expect(default_document_index_view_type).to eq(:gallery)
      end
    end

    context "with PressCatalogController and press with default list view" do
      let(:press) { Press.new(default_list_view: true) }
      before do
        allow(controller).to receive(:is_a?).with(PressCatalogController).and_return(true)
      end
      it 'returns press list view' do
        @press = press
        expect(default_document_index_view_type).to eq(:list)
      end
    end

    context "with a controller other than PressCatalogController" do
      it 'returns default list view' do
        expect(default_document_index_view_type).to eq(:list)
      end
    end
  end

  describe '#document_index_view_type' do
    let(:press) { Press.new(subdomain: 'barpublishing', default_list_view: false) }

    before do
      allow(controller).to receive(:is_a?).with(PressCatalogController).and_return(true)
      allow(self).to receive(:document_index_views).and_return(list: {}, gallery: {})
      @press = press
      session[:preferred_press_view] = 'gallery'
    end

    it 'forces BAR text searches into list view, including explicit gallery URLs' do
      expect(document_index_view_type(q: 'stone', view: 'gallery')).to eq :list
      expect(document_index_view_type(q: 'stone', f: { creator_sim: ['Hill'] })).to eq :list
      expect(session[:preferred_press_view]).to eq 'gallery'
    end

    it 'preserves gallery browsing for absent, blank, and facet-only searches' do
      expect(document_index_view_type({})).to eq :gallery
      expect(document_index_view_type(q: ' ')).to eq :gallery
      expect(document_index_view_type(f: { creator_sim: ['Hill'] })).to eq :gallery
      expect(document_index_view_type(view: 'list')).to eq :list
    end

    it 'does not force text searches for other presses into list view' do
      @press.subdomain = 'michigan'
      expect(document_index_view_type(q: 'stone', view: 'gallery')).to eq :gallery
    end
  end
end
