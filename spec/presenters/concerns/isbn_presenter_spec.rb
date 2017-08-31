# frozen_string_literal: true

require 'rails_helper'

class Presenter
  include ISBNPresenter
  attr_reader :solr_document

  def initialize(solr_document)
    @solr_document = solr_document
  end
end

describe ISBNPresenter do
  let(:presenter) { Presenter.new(build(:solr_document)) }

  describe 'presenter' do
    subject { presenter }
    it 'includes TitlePresenter' do
      is_expected.to be_a described_class
    end
  end

  describe '#isbn?' do
    subject { presenter.isbn? }
    before do
      allow(presenter).to receive(:isbn_hardcover?).and_return(false)
      allow(presenter).to receive(:isbn_paper?).and_return(false)
      allow(presenter).to receive(:isbn_ebook?).and_return(false)
    end
    context 'default' do
      it { is_expected.to be false }
    end
    context 'isbn hardcover' do
      before { allow(presenter).to receive(:isbn_hardcover?).and_return(true) }
      it { is_expected.to be true }
    end
    context 'isbn paper' do
      before { allow(presenter).to receive(:isbn_paper?).and_return(true) }
      it { is_expected.to be true }
    end
    context 'isbn ebook' do
      before { allow(presenter).to receive(:isbn_ebook?).and_return(true) }
      it { is_expected.to be true }
    end
  end

  describe '#isbn_hardcover?' do
    subject { presenter.isbn_hardcover? }
    context 'undef' do
      it { is_expected.to be false }
    end
    context 'def' do
      context 'blank' do
        before do
          def presenter.isbn
            []
          end
        end
        it { is_expected.to be false }
      end
      context 'present' do
        before do
          def presenter.isbn
            ['ISBN-HARDCOVER']
          end
        end
        it { is_expected.to be true }
      end
    end
  end

  describe '#isbn_paper?' do
    subject { presenter.isbn_paper? }
    context 'undef' do
      it { is_expected.to be false }
    end
    context 'def' do
      context 'blank' do
        before do
          def presenter.isbn_paper
            []
          end
        end
        it { is_expected.to be false }
      end
      context 'present' do
        before do
          def presenter.isbn_paper
            ['ISBN-PAPER']
          end
        end
        it { is_expected.to be true }
      end
    end
  end

  describe '#isbn_ebook?' do
    subject { presenter.isbn_ebook? }
    context 'undef' do
      it { is_expected.to be false }
    end
    context 'def' do
      context 'blank' do
        before do
          def presenter.isbn_ebook
            []
          end
        end
        it { is_expected.to be false }
      end
      context 'present' do
        before do
          def presenter.isbn_ebook
            ['ISBN-EBOOK']
          end
        end
        it { is_expected.to be true }
      end
    end
  end
end
