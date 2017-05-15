# frozen_string_literal: true

require 'rails_helper'

describe PressHelper do
  before { Press.destroy_all }

  describe "#press_subdomain" do
    context "when on a press page" do
      it "returns the press subdomain from the press model" do
        @press = Press.create(subdomain: "Bob's Bargain Books")
        expect(press_subdomain).to eq("Bob's Bargain Books")
      end
    end

    context "when on a monograph_catalog page" do
      let(:mono_doc) { SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph'], press_tesim: ["Book O' Rama"]) }

      it "returns the press subdomain from the monograph_presenter" do
        @monograph_presenter = Hyrax::MonographPresenter.new(mono_doc, nil)
        expect(press_subdomain).to eq("Book O' Rama")
      end
    end

    context "when on a file_set page" do
      let(:monograph) { create(:monograph, press: "Booksplosion!") }
      let(:file_set_doc) { SolrDocument.new(id: "fileset1", has_model_ssim: ['FileSet'], monograph_id_ssim: [monograph.id]) }

      it "returns the press subdomain from the file_set presenter" do
        @presenter = Hyrax::FileSetPresenter.new(file_set_doc, nil)
        expect(press_subdomain).to eq("Booksplosion!")
      end
    end

    context "when there's no press subdomain" do
      it "returns nil" do
        expect(press_subdomain).to be_nil
      end
    end
  end

  describe "#google_analytics" do
    context "when a press has a google_analytics id" do
      let(:press) { create(:press, subdomain: "ReadReadRead", google_analytics: '1-XX') }

      it "returns the ga id" do
        expect(google_analytics(press.subdomain)).to eq("1-XX")
      end
    end

    # google_analytics is now required
    # context "when a press doesn't have a google_analytics id" do
    #   let(:press) { create(:press, subdomain: "Big Brown Book Barn") }
    #
    #   it "returns nil" do
    #     expect(google_analytics(press.subdomain)).to be_nil
    #   end
    # end
  end
end
