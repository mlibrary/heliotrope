# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::MonographPresenter do
  include ActionView::Helpers::UrlHelper

  let(:presenter) { Hyrax::MonographPresenter.new(mono_doc, ability) }
  let(:mono_doc) { ::SolrDocument.new(id: 'mono', has_model_ssim: ['Monograph']) }
  let(:ability) { double('ability') }

  describe '#previous_edition_presenter' do
    subject { presenter.previous_edition_presenter }

    context 'no previous edition link set' do
      before { allow(mono_doc).to receive(:previous_edition).and_return(nil) }

      it { expect(subject).to be nil }
    end

    context 'previous edition link contains the DOI of another Monograph with necessary fields set' do
      let(:previous_edition_mono_doc) { ::SolrDocument.new(id: '000000000', has_model_ssim: ['Monograph'],
                                                           edition_name_tesim: ['Second Edition'],
                                                           isbn_tesim: ['978-0-472-55555-3 (ebook)'],
                                                           doi_ssim: ['10.3998/mpub.5555555']) }

      before do
        allow(mono_doc).to receive(:previous_edition).and_return('https://doi.org/10.3998/mpub.5555555')
        # SolrService.add takes hashes not docs!
        ActiveFedora::SolrService.add([previous_edition_mono_doc.to_h])
        ActiveFedora::SolrService.commit
      end

      context 'user cannot read the linked previous_edition Monograph' do
        before { allow(ability).to receive(:can?).with(:read, '000000000').and_return(false) }

        it 'does not instantiate a MonographPresenter' do
          expect(subject).to be_nil
        end
      end

      context 'user can read the linked previous_edition Monograph' do
        before { allow(ability).to receive(:can?).with(:read, '000000000').and_return(true) }

        it 'instantiates a MonographPresenter' do
          expect(subject).to be_present
          expect(subject).to be_an_instance_of(Hyrax::MonographPresenter)
          expect(subject.edition_name).to eq ', <i>Second Edition</i>'
          expect(subject.isbn_noformat).to eq ['978-0-472-55555-3']
          expect(subject.doi_path).to eq '10.3998/mpub.5555555'
        end
      end
    end
  end

  describe '#previous_edition_url' do
    subject { presenter.previous_edition_url }

    context 'no previous edition link set' do
      before { allow(mono_doc).to receive(:previous_edition).and_return(nil) }
      it { expect(subject).to be nil }
    end

    context "a DOI matching a Fulcrum Monograph's DOI" do
      let(:previous_edition_mono_doc) { ::SolrDocument.new(id: '0a0a0a0a0', has_model_ssim: ['Monograph'],
                                                           doi_ssim: ['10.3998/mpub.blah']) }
      before do
        allow(mono_doc).to receive(:previous_edition).and_return('https://doi.org/10.3998/mpub.blah')
        # SolrService.add takes hashes not docs!
        ActiveFedora::SolrService.add([previous_edition_mono_doc.to_h])
        ActiveFedora::SolrService.commit
      end

      context 'user cannot read the linked previous_edition Monograph' do
        before { allow(ability).to receive(:can?).with(:read, '0a0a0a0a0').and_return(false) }
        it { expect(subject).to eq(nil) }
      end

      context 'user can read the linked previous_edition Monograph' do
        before { allow(ability).to receive(:can?).with(:read, '0a0a0a0a0').and_return(true) }
        it { expect(subject).to eq('https://doi.org/10.3998/mpub.blah') }
      end
    end

    context 'a direct Fulcrum Monograph link' do
      before do
        allow(mono_doc).to receive(:previous_edition).and_return('https://test.host/concern/monographs/111111111')
      end

      context 'user cannot read the linked previous_edition Monograph' do
        before { allow(ability).to receive(:can?).with(:read, '111111111').and_return(false) }
        it { expect(subject).to eq(nil) }
      end

      context 'user can read the linked previous_edition Monograph' do
        before { allow(ability).to receive(:can?).with(:read, '111111111').and_return(true) }
        it { expect(subject).to eq('https://test.host/concern/monographs/111111111') }
      end
    end

    context 'external links' do
      context 'is not a url' do
        before { allow(mono_doc).to receive(:previous_edition).and_return('stuff') }
        it { expect(subject).to eq(nil) }
      end

      context 'is a url' do
        before { allow(mono_doc).to receive(:previous_edition).and_return('https://stuff') }
        it { expect(subject).to eq('https://stuff') }
      end
    end
  end

  describe '#next_edition_url' do
    subject { presenter.next_edition_url }

    context 'no next edition link set' do
      before { allow(mono_doc).to receive(:next_edition).and_return(nil) }
      it { expect(subject).to be nil }
    end

    context "a DOI matching a Fulcrum Monograph's DOI" do
      let(:next_edition_mono_doc) { ::SolrDocument.new(id: '1a1a1a1a1', has_model_ssim: ['Monograph'],
                                                           doi_ssim: ['10.3998/mpub.thingy']) }
      before do
        allow(mono_doc).to receive(:next_edition).and_return('https://doi.org/10.3998/mpub.thingy')
        # SolrService.add takes hashes not docs!
        ActiveFedora::SolrService.add([next_edition_mono_doc.to_h])
        ActiveFedora::SolrService.commit
      end

      context 'user cannot read the linked next_edition Monograph' do
        before { allow(ability).to receive(:can?).with(:read, '1a1a1a1a1').and_return(false) }
        it { expect(subject).to eq(nil) }
      end

      context 'user can read the linked next_edition Monograph' do
        before { allow(ability).to receive(:can?).with(:read, '1a1a1a1a1').and_return(true) }
        it { expect(subject).to eq('https://doi.org/10.3998/mpub.thingy') }
      end
    end

    context 'a direct Fulcrum Monograph link' do
      before do
        allow(mono_doc).to receive(:next_edition).and_return('https://test.host/concern/monographs/222222222')
      end

      context 'user cannot read the linked next_edition Monograph' do
        before { allow(ability).to receive(:can?).with(:read, '222222222').and_return(false) }
        it { expect(subject).to eq(nil) }
      end

      context 'user can read the linked next_edition Monograph' do
        before { allow(ability).to receive(:can?).with(:read, '222222222').and_return(true) }
        it { expect(subject).to eq('https://test.host/concern/monographs/222222222') }
      end
    end

    context 'external links' do
      context 'is not a url' do
        before { allow(mono_doc).to receive(:next_edition).and_return('blah') }
        it { expect(subject).to eq(nil) }
      end

      context 'is a url' do
        before { allow(mono_doc).to receive(:next_edition).and_return('https://stuff') }
        it { expect(subject).to eq('https://stuff') }
      end
    end
  end

  describe '#previous_edition_noid' do
    subject { presenter.previous_edition_noid }

    context 'no previous edition link set' do
      before { allow(mono_doc).to receive(:previous_edition).and_return(nil) }
      it { expect(subject).to be nil }
    end

    context 'not a Fulcrum link' do
      before { allow(mono_doc).to receive(:previous_edition).and_return('http://example.com') }
      it { expect(subject).to be nil }
    end

    context 'Fulcrum FileSet link' do
      before { allow(mono_doc).to receive(:previous_edition).and_return('https://test.host/concern/file_sets/333333333') }
      it { expect(subject).to be nil }
    end

    context 'not a Fulcrum link' do
      before { allow(mono_doc).to receive(:previous_edition).and_return('https://test.host/concern/monographs/333333333') }
      it { expect(subject).to eq('333333333') }
    end
  end

  describe '#next_edition_noid' do
    subject { presenter.next_edition_noid }

    context 'no next edition link set' do
      before { allow(mono_doc).to receive(:next_edition).and_return(nil) }
      it { expect(subject).to be nil }
    end

    context 'not a Fulcrum link' do
      before { allow(mono_doc).to receive(:next_edition).and_return('http://example.com') }
      it { expect(subject).to be nil }
    end

    context 'Fulcrum FileSet link' do
      before { allow(mono_doc).to receive(:next_edition).and_return('https://test.host/concern/file_sets/444444444') }
      it { expect(subject).to be nil }
    end

    context 'not a Fulcrum link' do
      before { allow(mono_doc).to receive(:next_edition).and_return('https://test.host/concern/monographs/444444444') }
      it { expect(subject).to eq('444444444') }
    end
  end

  describe '#edition_name' do
    subject { presenter.edition_name }

    context 'edition_name missing, no link to another edition' do
      before { allow(mono_doc).to receive(:edition_name).and_return(nil) }
      it { expect(subject).to be nil }
    end

    context 'edition_name missing, link to previous_edition present' do
      before do
        allow(mono_doc).to receive(:edition_name).and_return(nil)
        allow(mono_doc).to receive(:previous_edition).and_return('http://example.com/1')
      end
      it { expect(subject).to be ' Edition' }
    end

    context 'edition_name missing, link to next_edition present' do
      before do
        allow(mono_doc).to receive(:edition_name).and_return(nil)
        allow(mono_doc).to receive(:next_edition).and_return('http://example.com/2')
      end
      it { expect(subject).to be ' Edition' }
    end

    context 'edition_name exists and does not have "edition" in it' do
      before { allow(mono_doc).to receive(:edition_name).and_return('with a new foreword by Pippa Peg') }
      it { expect(subject).to eq ' Edition, <i>with a new foreword by Pippa Peg</i>' }
    end

    context 'edition_name exists and has "edition" in it' do
      before { allow(mono_doc).to receive(:edition_name).and_return('New and expanded edition') }
      it { expect(subject).to eq ', <i>New and expanded edition</i>' }
    end

    context 'edition_name exists and has "Edition" in it' do
      before { allow(mono_doc).to receive(:edition_name).and_return('New and Revised Edition') }
      it { expect(subject).to eq ', <i>New and Revised Edition</i>' }
    end
  end
end
