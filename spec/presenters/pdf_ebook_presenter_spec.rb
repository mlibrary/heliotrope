# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PDFEbookPresenter do
  subject(:presenter) { described_class.new(pdf_ebook) }

  let(:pdf_ebook) { instance_double(PDFEbook::Publication, 'pdf_ebook', id: 'id', intervals: intervals) }
  let(:intervals) { [] }

  describe '#id' do
    subject { presenter.id }

    it { is_expected.to eq(pdf_ebook.id) }
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
