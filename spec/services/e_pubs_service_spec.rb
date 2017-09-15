# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubsService do
  before { FileUtils.rm_rf(described_class.epubs_path) }

  let(:noid) { 'validnoid' }
  let(:id) { epub.id }
  let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
  let(:file_entry) { "META-INF/container.xml" }

  describe '#factory' do
    subject { described_class.factory(id) }

    context 'nil id' do
      let(:id) { nil }
      it 'returns a null object' do
        is_expected.to be_an_instance_of(EPub::PublicationNullObject)
      end
    end
    context 'id not found' do
      let(:id) { noid }
      it 'returns a null object' do
        is_expected.to be_an_instance_of(EPub::PublicationNullObject)
      end
    end
    context 'file set id' do
      context 'file set is an epub' do
        it 'returns an epub' do
          is_expected.to be_an_instance_of(EPub::Publication)
          expect(subject.id).to eq id
        end
      end
      context 'file set is not an epub' do
        let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }
        it 'returns a null object' do
          is_expected.to be_an_instance_of(EPub::PublicationNullObject)
        end
      end
    end
  end

  describe '#open' do
    subject { described_class.open(id) }

    context 'file_set is an epub' do
      it 'opens the EPub file' do
        expect { subject }.not_to raise_error
      end
    end
    context 'file_set is not an epub' do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }
      it 'opens the EPub file' do
        expect { subject }.not_to raise_error
      end
    end

    context 'file_set does not exist' do
      before { allow(epub).to receive(:id).and_return(noid) }
      it 'raises ActiveFedora::ObjectNotFoundError' do
        expect { subject }.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
    end
  end

  describe '#read' do
    subject { described_class.read(id, file_entry) }

    context 'file_set is an epub' do
      context 'entry file exist' do
        it 'reads the entry file' do
          expect(subject).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?><container xmlns=\"urn:oasis:names:tc:opendocument:xmlns:container\" version=\"1.0\">\n<rootfiles>\n<rootfile full-path=\"OPS/package.opf\" media-type=\"application/oebps-package+xml\"/>\n</rootfiles>\n</container>")
        end
      end
      context 'file_entry does not exist.' do
        let(:file_entry) { "META-INF/container.txt" }
        it 'raises EPubsServiceError' do
          expect { subject }.to raise_error(EPubsServiceError, "Entry #{file_entry} in EPub #{id} does not exist.")
        end
      end
    end
    context 'file_set is not an epub' do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }
      it 'raises EPubsServiceError' do
        expect { subject }.to raise_error(EPubsServiceError, "EPub #{id} is corrupt.")
      end
    end
    context 'file_set does not exist' do
      before { allow(epub).to receive(:id).and_return(noid) }
      it 'raises ActiveFedora::ObjectNotFoundError' do
        expect { subject }.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
    end
  end

  describe '#close' do
    subject { described_class.close(id) }

    context 'file_set is an epub' do
      it 'closes the EPub file' do
        expect { subject }.not_to raise_error
        expect(Dir.exist?(described_class.epub_path(id))).to be false
      end
    end

    context 'file_set is not an epub' do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }
      it 'closes the EPub file' do
        expect { subject }.not_to raise_error      end
    end

    context 'file_set does not exist' do
      before { allow(epub).to receive(:id).and_return(noid) }
      it 'closes the EPub file' do
        expect { subject }.not_to raise_error      end
    end
  end

  describe '#cache_epub_entry' do
    subject { described_class.cache_epub_entry(id, file_entry) }

    context 'entry file exist in epub' do
      it 'unzips the epub entry' do
        subject
        expect(File.exist?(described_class.epub_entry_path(id, file_entry))).to be true
      end
    end
    context 'entry file does not exist in epub' do
      let(:file_entry) { "entry/file.xml" }
      it 'raises EPubsServiceError' do
        expect { subject }.to raise_error(EPubsServiceError, "Entry #{file_entry} in EPub #{id} does not exist.")
      end
    end
    context 'epub is nil' do
      let(:epub) { create(:file_set) }
      it 'raises EPubsServiceError' do
        expect { subject }.to raise_error(EPubsServiceError, "EPub #{id} file is nil.")
      end
    end
  end

  describe '#cache_epub' do
    subject { described_class.cache_epub(id) }

    context 'epub' do
      it 'unzips the epub' do
        subject
        expect(Dir.exist?(described_class.epub_path(id))).to be true
      end
    end
    context 'epub is nil' do
      let(:epub) { create(:file_set) }
      it 'raises EPubsServiceError' do
        expect { subject }.to raise_error(EPubsServiceError, "EPub #{id} file is nil.")
      end
    end
  end

  describe '#prune_cache' do
    subject { described_class.prune_cache }

    before { described_class.cache_epub(id) }
    context 'within the 24 hour cache window' do
      it 'does not remove the epub' do
        subject
        expect(Dir.exist?(described_class.epub_path(id))).to be true
      end
    end
    context 'outside the 24 hour cache window' do
      before { FileUtils.touch(described_class.epub_path(id), mtime: Time.now - 1.day) }
      it 'removes the epub' do
        subject
        expect(Dir.exist?(described_class.epub_path(id))).to be false
      end
    end
  end

  describe '#prune_cache_epub' do
    subject { described_class.prune_cache_epub(id) }

    before { described_class.cache_epub(id) }
    it 'removes the epub' do
      subject
      expect(Dir.exist?(described_class.epub_path(id))).to be false
    end
  end

  describe '#clear_cache' do
    subject { described_class.clear_cache }

    before { described_class.cache_epub(id) }
    it 'removes the unzipped epub' do
      subject
      expect(Dir.exist?(described_class.epub_path(id))).to be false
    end
  end
end
