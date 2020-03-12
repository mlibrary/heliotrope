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
end
