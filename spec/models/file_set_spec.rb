# frozen_string_literal: true

require 'rails_helper'

describe FileSet do
  let(:file_set) { described_class.new }
  let(:sort_date) { '2014-01-03' }
  let(:bad_sort_date) { 'NOT-A-DATE' }

  it 'has a valid sort_date' do
    file_set.sort_date = sort_date
    file_set.apply_depositor_metadata('admin@example.com')
    expect(file_set.save!).to be true
    expect(file_set.reload.sort_date).to eq sort_date
  end

  it 'does not have an valid sort date' do
    file_set.sort_date = bad_sort_date
    file_set.apply_depositor_metadata('admin@example.com')
    expect { file_set.save! }.to raise_error(ActiveFedora::RecordInvalid)
  end

  describe 'property :content_type' do
    context 'attribute' do
      subject { described_class.delegated_attributes[:content_type] }

      it 'is a multiple' do
        expect(subject.multiple).to be true
      end
    end

    context 'index configuration' do
      subject { described_class.index_config[:content_type] }

      it 'is stored searchable' do
        expect(subject.behaviors).to include(:stored_searchable)
      end
      it 'is facetable' do
        expect(subject.behaviors).to include(:facetable)
      end
      it 'is a string' do
        expect(subject.data_type).to eq :string
      end
    end

    context 'predicate' do
      subject { described_class.reflect_on_property(:content_type) }

      it 'is SCHEMA.contentType' do
        expect(subject.predicate).to eq ::RDF::Vocab::SCHEMA.contentType
      end
    end
  end

  context 'handles' do
    let(:file_set) { build(:file_set, id: noid) }
    let(:noid) { 'validnoid' }

    before do
      ActiveFedora::Cleaner.clean!
      allow(HandleCreateJob).to receive(:perform_later).with(noid)
      allow(HandleDeleteJob).to receive(:perform_later).with(noid)
    end

    it 'creates a handle after create and deletes the handle after destroy' do
      file_set.save
      expect(HandleCreateJob).to have_received(:perform_later).with(noid)
      file_set.destroy
      expect(HandleDeleteJob).to have_received(:perform_later).with(noid)
    end
  end

  describe 'shortcut methods for mime types' do
    let(:file_set) { create(:file_set) }

    context 'video?' do
      subject { file_set.video? }

      before do
        allow(file_set).to receive(:mime_type).and_return('video/mpg')
      end

      it 'returns true for a mime type of `video/mpg`' do
        expect(subject).to be true
      end
    end
  end
end
