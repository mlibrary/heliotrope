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
        @presenter = Hyrax::MonographPresenter.new(mono_doc, nil)
        expect(press_subdomain).to eq("Book O' Rama")
      end
    end

    context "when on a file_set page" do
      let(:mono_doc) { SolrDocument.new(id: 'mono', press_tesim: ["Booksplosion!"], has_model_ssim: ['Monograph'], member_ids_ssim: ['fileset1']) }
      let(:file_set_doc) { SolrDocument.new(id: "fileset1", has_model_ssim: ['FileSet']) }

      before do
        ActiveFedora::SolrService.add([mono_doc.to_h, file_set_doc.to_h])
        ActiveFedora::SolrService.commit
      end

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
      let(:press) { create(:press, subdomain: "readreadread", google_analytics: '1-XX') }

      it "returns the ga id" do
        expect(google_analytics(press.subdomain)).to eq("1-XX")
      end
    end
  end

  describe "#google_analytics_url" do
    context "when a press has a google_analytics URL" do
      let(:press) { create(:press, subdomain: "readreadread", google_analytics_url: 'https://www.example.com/GA/readreadread') }

      it "returns the ga URL" do
        expect(google_analytics_url(press.subdomain)).to eq('https://www.example.com/GA/readreadread')
      end
    end
  end

  describe "#readership_map_url" do
    context "when a press has a readership map URL" do
      let(:press) { create(:press, subdomain: "readreadread", readership_map_url: 'https://www.example.com/Map/readreadread') }

      it "returns the map URL" do
        expect(readership_map_url(press.subdomain)).to eq('https://www.example.com/Map/readreadread')
      end
    end
  end

  describe "#restricted_message" do
    let(:press) { create(:press, subdomain: "blah", restricted_message: "<b>No. Just No.</b>") }

    it "returns the restricted_message" do
      expect(restricted_message(press.subdomain)).to eq "<b>No. Just No.</b>"
    end
  end

  describe "when a child press has a parent" do
    let(:press) {
      create(:press, subdomain: "blue",
                     name: "Blue Press",
                     logo_path: Rack::Test::UploadedFile.new(File.open(Rails.root.join('spec', 'fixtures', 'csv', 'import', 'shipwreck.jpg')), 'image/jpg'),
                     description: "This is Blue Press",
                     press_url: "http://blue.com",
                     google_analytics: "GA-ID-BLUE",
                     google_analytics_url: 'https://www.example.com/GA/readreadread',
                     typekit: "BLUE-TYPEKIT",
                     footer_block_a: "blue-footer-a",
                     footer_block_b: "blue-footer-b",
                     footer_block_c: "blue-footer-c",
                     parent_id: nil)
    }
    let(:child) {
      create(:press, subdomain: "maize",
                     name: "Maize Press",
                     logo_path: Rack::Test::UploadedFile.new(File.open(Rails.root.join('spec', 'fixtures', 'csv', 'import', 'miranda.jpg')), 'image/jpg'),
                     description: "This is Maize Press",
                     press_url: "http://blue.com/maize",
                     google_analytics: nil, # factorybot will fake a ga-id without this
                     google_analytics_url: nil,
                     parent_id: press.id)
    }

    context "when the child is missing a field" do
      it "uses the parent's field" do
        expect(footer_block_a(child.subdomain)).to eq press.footer_block_a
        expect(footer_block_b(child.subdomain)).to eq press.footer_block_b
        expect(footer_block_c(child.subdomain)).to eq press.footer_block_c
        expect(google_analytics(child.subdomain)).to eq press.google_analytics
        expect(google_analytics_url(child.subdomain)).to eq press.google_analytics_url
        expect(typekit(child.subdomain)).to eq press.typekit
      end
      it "does not use the parent's name, since a name is required for all presses" do
        expect(name(child.subdomain)).to eq child.name
      end
    end

    describe "#press_subdomains" do
      it "returns the press's subdomains in the right order, child then parent" do
        expect(press_subdomains(child.subdomain)).to eq [child.subdomain, press.subdomain]
      end
    end
  end

  describe "#all_google_analytics with two GA ids" do
    let(:press) { create(:press, subdomain: "blue", google_analytics: "GA-ID-BLUE") }
    let(:child) { create(:press, subdomain: "maize", google_analytics: "GA-ID-MAIZE", parent_id: press.id) }

    it "returns both Google analytics ids" do
      expect(all_google_analytics(child.subdomain)).to match_array [press.google_analytics, child.google_analytics]
    end
  end

  describe "#show_banner?" do
    subject { show_banner?(actor, subdomain) }

    def banner_product(_subdomain)
      subdomain_product
    end

    let(:actor) { double('actor') }
    let(:subdomain) { 'subdomain' }
    let(:subdomain_product) { nil }
    let(:actor_products) { [] }

    before { allow(Greensub).to receive(:actor_products).with(actor).and_return(actor_products) }

    it { is_expected.to be false }

    context 'subdomain_product' do
      let(:product) { double('product', name: 'name', purchase: 'purchase') }
      let(:subdomain_product) { product }

      it { is_expected.to be false }

      context 'press catalog' do
        before { allow(controller).to receive(:is_a?).with(PressCatalogController).and_return(true) }

        it { is_expected.to be true }

        context 'actor has product' do
          let(:actor_products) { [product] }

          it { is_expected.to be false }
        end
      end

      context 'monograph catalog' do
        let(:monograph) { double('monograph', valid?: true) }
        let(:open_access) { false }
        let(:product_include) { true }

        before do
          allow(controller).to receive(:is_a?).with(PressCatalogController).and_return(false)
          allow(controller).to receive(:is_a?).with(MonographCatalogController).and_return(true)
          allow(Greensub).to receive(:product_include?).with(product: product, entity: monograph).and_return(product_include)
          allow(Sighrax).to receive(:from_noid).and_return(monograph)
          allow(Sighrax).to receive(:open_access?).with(monograph).and_return(open_access)
        end

        it { is_expected.to be true }

        context 'actor has product' do
          let(:actor_products) { [product] }

          it { is_expected.to be false }
        end

        context 'open access' do
          let(:open_access) { true }

          it { is_expected.to be false }
        end

        context 'not included in product' do
          let(:product_include) { false }

          it { is_expected.to be false }
        end
      end
    end
  end

  describe "#banner_product" do
    subject { banner_product(subdomain) }

    let(:subdomain) { 'subdomain' }
    let(:ebc_product) { create(:product, identifier: 'ebc_backlist') }
    let(:nag_product) { create(:product, identifier: 'nag_' + Time.current.year.to_s) }

    before do
      ebc_product
      nag_product
    end

    it { is_expected.to be nil }

    context 'michigan' do
      let(:subdomain) { 'michigan' }

      it { is_expected.to eq ebc_product }
    end

    context 'child of michigan' do
      let(:subdomain) { 'wolverine' }
      let(:publisher) { instance_double(Sighrax::Publisher, 'publisher', parent: parent_publisher) }
      let(:parent_publisher) { instance_double(Sighrax::Publisher, 'parent_publisher', valid?: true, subdomain: parent_subdomain) }
      let(:parent_subdomain) { 'michigan' }

      before { allow(Sighrax::Publisher).to receive(:from_subdomain).with(subdomain).and_return(publisher) }

      it { is_expected.to eq ebc_product }
    end

    context 'heliotrope' do
      let(:subdomain) { 'heliotrope' }

      it { is_expected.to eq nag_product }
    end
  end
end
