# frozen_string_literal: true

require 'rails_helper'

describe BannerHelper do
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

  describe "#show_acceptable_use_policy?" do
    subject { show_acceptable_use_policy?(subdomain) }

    context "a press with a custom eula does not show the default acceptable use policy" do
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

    context 'a press without a custom eula gets the default acceptable use policy' do
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
  end
end
