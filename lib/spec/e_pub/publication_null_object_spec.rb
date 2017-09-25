# frozen_string_literal: true

RSpec.describe EPub::PublicationNullObject do
  # Class Methods

  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end

  # Instance Methods

  describe '#id' do
    subject { EPub::Publication.null_object.id }
    it 'returns "epub_null"' do
      is_expected.to eq 'epub_null'
    end
  end

  describe '#chapters' do
    subject { EPub::Publication.null_object.chapters }
    it 'returns an empty array' do
      is_expected.to be_an_instance_of(Array)
      is_expected.to be_empty
    end
  end

  describe '#presenter' do
    subject { EPub::Publication.null_object.presenter }

    it 'returns an publication presenter' do
      is_expected.to be_an_instance_of(EPub::PublicationPresenter)
      expect(subject.id).to eq 'epub_null'
    end
  end

  describe '#purge' do
    subject { EPub::Publication.null_object.purge }
    it { is_expected.to eq nil }
  end

  describe '#read' do
    subject { EPub::Publication.null_object.read(file_entry) }

    let(:file_entry) { double('file_entry') }

    it 'returns an empty string' do
      is_expected.to be_a(String)
      is_expected.to be_empty
    end
  end

  describe '#search' do
    subject { EPub::Publication.null_object.search(query) }
    let(:query) { double("query") }
    it 'returns an empty results hash' do
      is_expected.to be_a(Hash)
      expect(subject[:q]).to eq query
      expect(subject[:search_results]).to eq([])
    end
  end
end
