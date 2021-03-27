# frozen_string_literal: true

require 'rails_helper'

describe BannerHelper do
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
        let(:monograph) { instance_double(Sighrax::Monograph, 'monograph', valid?: true, open_access?: open_access) }
        let(:open_access) { false }
        let(:product_include) { true }
        let(:@presenter) { instance_double(Hyrax::MonographPresenter, 'presenter') }

        before do
          allow(controller).to receive(:is_a?).with(PressCatalogController).and_return(false)
          allow(controller).to receive(:is_a?).with(MonographCatalogController).and_return(true)
          allow(Greensub).to receive(:product_include?).with(product: product, entity: monograph).and_return(product_include)
          allow(Sighrax).to receive(:from_presenter).with(@presenter).and_return(monograph)
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

  describe "#show_eula?" do
    subject { show_eula?(subdomain) }

    context 'press wants EULA' do
      let(:subdomain) { 'barpublishing' }

      context 'not press or monograph catalog' do
        before do
          allow(controller).to receive(:is_a?).with(PressCatalogController).and_return(false)
          allow(controller).to receive(:is_a?).with(MonographCatalogController).and_return(false)
        end

        it { is_expected.to be false }
      end

      context 'press catalog' do
        before do
          allow(controller).to receive(:is_a?).with(PressCatalogController).and_return(true)
          allow(controller).to receive(:is_a?).with(MonographCatalogController).and_return(false)
        end

        it { is_expected.to be true }
      end

      context 'monograph catalog' do
        before do
          allow(controller).to receive(:is_a?).with(PressCatalogController).and_return(false)
          allow(controller).to receive(:is_a?).with(MonographCatalogController).and_return(true)
        end

        it { is_expected.to be true }
      end
    end

    context 'press does not want EULA' do
      let(:subdomain) { 'blahpress' }

      context 'not press or monograph catalog' do
        before do
          allow(controller).to receive(:is_a?).with(PressCatalogController).and_return(false)
          allow(controller).to receive(:is_a?).with(MonographCatalogController).and_return(false)
        end

        it { is_expected.to be false }
      end

      context 'press catalog' do
        before do
          allow(controller).to receive(:is_a?).with(PressCatalogController).and_return(true)
          allow(controller).to receive(:is_a?).with(MonographCatalogController).and_return(false)
        end

        it { is_expected.to be false }
      end

      context 'monograph catalog' do
        before do
          allow(controller).to receive(:is_a?).with(PressCatalogController).and_return(false)
          allow(controller).to receive(:is_a?).with(MonographCatalogController).and_return(true)
        end

        it { is_expected.to be false }
      end
    end
  end
end
