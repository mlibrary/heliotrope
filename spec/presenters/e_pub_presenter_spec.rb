# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPresenter do
  subject(:presenter) { described_class.new(epub) }

  let(:epub) { instance_double(EPub::Publication, 'epub', id: 'id', rendition: rendition, multi_rendition?: multi_rendition) }
  let(:multi_rendition) { false }
  let(:rendition) { instance_double(EPub::Rendition, 'rendition', intervals: intervals) }
  let(:intervals) { [] }

  describe '#id' do
    subject { presenter.id }

    it { is_expected.to eq(epub.id) }
  end

  describe '#multi_rendition?' do
    subject { presenter.multi_rendition? }

    it { is_expected.to be false }

    context 'multi_rendition' do
      let(:multi_rendition) { true }

      it { is_expected.to be true }
    end
  end

  describe '#intervals?' do
    subject { presenter.intervals? }

    it { is_expected.to be false }

    context 'intervals' do
      let(:intervals) { [interval] }
      let(:interval) { double('interval') }

      it { is_expected.to be true }
    end
  end

  describe '#intervals' do
    subject { presenter.intervals.first }

    it { is_expected.to be_nil }

    context 'intervals' do
      let(:intervals) { [interval] }
      let(:interval) { double('interval') }

      it { is_expected.to be_an_instance_of(EPubIntervalPresenter) }
    end
  end
end
