# frozen_string_literal: true

RSpec.describe EPub::Publication do
  let(:noid) { 'validnoid' }
  let(:non_noid) { 'invalidnoid' }

  before do
    allow(EPubsService).to receive(:open).with(noid).and_return(nil)
    allow(EPub::Cache).to receive(:cached?).with(noid).and_return(true)
  end

  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end

  describe '#from' do
    subject { described_class.from(data) }

    context 'null object' do
      context 'non hash' do
        context 'nil' do
          let(:data) { nil }

          it 'returns an instance of PublicationNullObject' do
            is_expected.to be_an_instance_of(EPub::PublicationNullObject)
          end
        end
        context 'non-noid' do
          let(:data) { non_noid }

          it 'returns an instance of PublicationNullObject' do
            is_expected.to be_an_instance_of(EPub::PublicationNullObject)
          end
        end
      end
      context 'hash' do
        context 'empty' do
          let(:data) { {} }

          it 'returns an instance of PublicationNullObject' do
            is_expected.to be_an_instance_of(EPub::PublicationNullObject)
          end
        end
        context 'nil' do
          let(:data) { { id: nil } }

          it 'returns an instance of PublicationNullObject' do
            is_expected.to be_an_instance_of(EPub::PublicationNullObject)
          end
        end
        context 'non-noid' do
          let(:data) { { id: non_noid } }

          it 'returns an instance of PublicationNullObject' do
            is_expected.to be_an_instance_of(EPub::PublicationNullObject)
          end
        end
      end
    end

    context 'publication' do
      context 'non hash' do
        let(:data) { noid }

        it 'returns an instance of a Publication' do
          is_expected.to be_an_instance_of(described_class)
        end
      end
      context 'hash' do
        let(:data) { { id: noid } }

        it 'returns an instance of a Publication' do
          is_expected.to be_an_instance_of(described_class)
        end
      end
    end
  end

  describe '#id' do
    subject { described_class.from(noid).id }
    it 'returns noid' do
      is_expected.to eq noid
    end
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it 'returns an instance of PublicationNullObject' do
      is_expected.to be_an_instance_of(EPub::PublicationNullObject)
    end
  end

  describe '#read' do
    subject { publication.read(file_entry) }

    let(:file_entry) { double("file_entry") }
    let(:text) { double("text") }

    before do
      allow(EPubsService).to receive(:read).with(noid, file_entry).and_return(text)
    end

    context 'publication null object' do
      let(:publication) { described_class.null_object }
      it 'returns null object read' do
        is_expected.not_to eq text
        is_expected.to eq described_class.null_object.read(file_entry)
      end
    end

    context 'publication' do
      let(:publication) { described_class.from(noid) }

      context 'epubs service returns text' do
        it 'returns text' do
          is_expected.to eq text
        end
      end

      context 'epubs service raises standard error' do
        before do
          allow(EPubsService).to receive(:read).with(noid, file_entry).and_raise(StandardError)
          @message = 'message'
          allow(EPub.logger).to receive(:info).with(any_args) { |value| @message = value }
        end

        it 'returns null object read' do
          is_expected.not_to eq text
          is_expected.to eq described_class.null_object.read(file_entry)
          expect(@message).not_to eq 'message'
          expect(@message).to eq '### INFO read #[Double "file_entry"] not found in publication validnoid raised StandardError ###'
        end
      end
    end
  end

  describe '#presenter' do
    subject { described_class.from(noid).presenter }

    it 'returns an publication presenter' do
      is_expected.to be_an_instance_of(EPub::PublicationPresenter)
      expect(subject.id).to eq noid
    end
  end

  describe '#search' do
    subject { publication.search(query) }

    let(:e_pubs_search_service) { double("e_pubs_search_service") }
    let(:query) { double("query") }
    let(:results) { double("results") }

    before do
      allow(EPubsSearchService).to receive(:new).with(noid).and_return(e_pubs_search_service)
      allow(e_pubs_search_service).to receive(:search).with(query).and_return(results)
    end

    context 'publication null object' do
      let(:publication) { described_class.null_object }
      it 'returns null object query' do
        is_expected.not_to eq results
        is_expected.to eq described_class.null_object.search(query)
      end
    end

    context 'publication' do
      let(:publication) { described_class.from(noid) }

      context 'epubs search service returns results' do
        it 'returns results' do
          is_expected.to eq results
        end
      end

      context 'epubs search service raises standard error' do
        before do
          allow(e_pubs_search_service).to receive(:search).with(query).and_raise(StandardError)
          @message = 'message'
          allow(EPub.logger).to receive(:info).with(any_args) { |value| @message = value }
        end

        it 'returns null object query' do
          is_expected.not_to eq results
          is_expected.to eq described_class.null_object.search(query)
          expect(@message).not_to eq 'message'
          expect(@message).to eq '### INFO query #[Double "query"] in publication validnoid raised StandardError at: e.backtrace[0] ###'
        end
      end
    end
  end
end
