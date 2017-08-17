# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubsService do
  let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
  let(:file_entry) { "META-INF/container.xml" }

  before { FileUtils.rm_rf(described_class.epubs_path) }

  describe '#open' do
    subject(:open) { described_class.open(epub_id) }
    let(:epub_id) { epub.id }

    context 'file_set is an epub' do
      it 'opens the EPub file' do
        expect { open }.not_to raise_error
      end
    end

    context 'file_set is not an epub' do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }
      it 'opens the EPub file' do
        expect { open }.not_to raise_error
      end
    end

    context 'file_set does not exist' do
      let(:epub_id) { "epub_id" }
      it 'raises ActiveFedora::ObjectNotFoundError' do
        expect { open }.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
    end
  end

  describe '#read' do
    subject(:read) { described_class.read(epub_id, file_entry) }
    let(:epub_id) { epub.id }
    context 'file_set is an epub' do
      it 'reads the entry file' do
        expect(read).to eq("<?xml version=\"1.0\" encoding=\"UTF-8\"?><container xmlns=\"urn:oasis:names:tc:opendocument:xmlns:container\" version=\"1.0\">\n<rootfiles>\n<rootfile full-path=\"OPS/package.opf\" media-type=\"application/oebps-package+xml\"/>\n</rootfiles>\n</container>")
      end
    end
    context 'file_set is an epub but file_entry does not exist.' do
      let(:file_entry) { "META-INF/container.txt" }
      it 'raises EPubsServiceError' do
        expect { read }.to raise_error(EPubsServiceError, "Entry #{file_entry} in EPub #{epub.id} does not exist.")
      end
    end
    context 'file_set is not an epub' do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }
      it 'raises EPubsServiceError' do
        expect { read }.to raise_error(EPubsServiceError, "EPub #{epub.id} is corrupt.")
      end
    end
    context 'file_set does not exist' do
      let(:epub_id) { "epub_id" }
      it 'raises ActiveFedora::ObjectNotFoundError' do
        expect { read }.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
    end
  end

  describe '#close' do
    subject(:close) { described_class.close(epub_id) }
    let(:epub_id) { epub.id }

    context 'file_set is an epub' do
      it 'closes the EPub file' do
        expect { close }.not_to raise_error
        expect(Dir.exist?(described_class.epub_path(epub.id))).to be false
      end
    end

    context 'file_set is not an epub' do
      let(:epub) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }
      it 'closes the EPub file' do
        expect { close }.not_to raise_error      end
    end

    context 'file_set does not exist' do
      let(:epub_id) { "epub_id" }
      it 'closes the EPub file' do
        expect { close }.not_to raise_error      end
    end
  end

  describe '#cache_epub_entry' do
    subject(:cache_epub_entry) { described_class.cache_epub_entry(epub.id, file_entry) }
    context 'entry file exist in epub' do
      it 'unzips the epub entry' do
        cache_epub_entry
        expect(File.exist?(described_class.epub_entry_path(epub.id, file_entry))).to be true
      end
    end
    context 'entry file does not exist in epub' do
      let(:file_entry) { "entry/file.xml" }
      it 'raises EPubsServiceError' do
        expect { cache_epub_entry }.to raise_error(EPubsServiceError, "Entry #{file_entry} in EPub #{epub.id} does not exist.")
      end
    end
    context 'epub is nil' do
      let(:epub) { create(:file_set) }
      it 'raises EPubsServiceError' do
        expect { cache_epub_entry }.to raise_error(EPubsServiceError, "EPub #{epub.id} file is nil.")
      end
    end
  end

  describe '#cache_epub' do
    subject(:cache_epub) { described_class.cache_epub(epub.id) }
    context 'epub' do
      it 'unzips the epub' do
        cache_epub
        expect(Dir.exist?(described_class.epub_path(epub.id))).to be true
      end
    end
    context 'epub is nil' do
      let(:epub) { create(:file_set) }
      it 'raises EPubsServiceError' do
        expect { cache_epub }.to raise_error(EPubsServiceError, "EPub #{epub.id} file is nil.")
      end
    end
  end

  describe '#prune_cache' do
    subject(:prune_cache) { described_class.prune_cache }
    before { described_class.cache_epub(epub.id) }
    context 'within the 24 hour cache window' do
      it 'does not remove the epub' do
        prune_cache
        expect(Dir.exist?(described_class.epub_path(epub.id))).to be true
      end
    end
    context 'outside the 24 hour cache window' do
      before { FileUtils.touch(described_class.epub_path(epub.id), mtime: Time.now - 1.day) }
      it 'removes the epub' do
        prune_cache
        expect(Dir.exist?(described_class.epub_path(epub.id))).to be false
      end
    end
  end

  describe '#prune_cache_epub' do
    subject(:prune_cache_epub) { described_class.prune_cache_epub(epub.id) }
    before { described_class.cache_epub(epub.id) }
    it 'removes the epub' do
      prune_cache_epub
      expect(Dir.exist?(described_class.epub_path(epub.id))).to be false
    end
  end

  describe '#clear_cache' do
    subject(:clear_cache) { described_class.clear_cache }
    before { described_class.cache_epub(epub.id) }
    it 'removes the unzipped epub' do
      clear_cache
      expect(Dir.exist?(described_class.epub_path(epub.id))).to be false
    end
  end
end
