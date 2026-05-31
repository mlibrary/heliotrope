require 'spec_helper'

describe Riiif::FileSystemFileResolver do
  let(:root) { File.expand_path(::File.join(::File.dirname(__FILE__), '../../..')) }
  let(:base_path) { ::File.join(root, 'spec/samples') }
  let(:resolver) { described_class.new(base_path: base_path) }

  describe '#find' do
    subject { resolver.find(id) }

    context "when the file isn't found" do
      let(:id) { '1234' }
      it 'raises an error' do
        expect { subject }.to raise_error Riiif::ImageNotFoundError
      end
    end

    context 'when a jpeg2000 file is found' do
      let(:id) { 'world' }
      it 'returns the jpeg2000 file' do
        expect(subject.path).to eq base_path + '/world.jp2'
      end
    end

    context 'when pattern is not permitted' do
      let(:id) { 'foo/bar' } # slashes are not permitted by default

      it 'casts the error to a not found (required by the IIIF spec)' do
        expect { subject.path }.to raise_error Riiif::ImageNotFoundError
      end
    end
  end

  describe '#input_types' do
    subject { resolver.send(:input_types) }

    it 'includes jp2 extension' do
      expect(subject).to include 'jp2'
    end

    it 'includes jpg extension' do
      expect(subject).to include 'jpg'
    end

    it 'includes tif extension' do
      expect(subject).to include 'tif'
    end

    it 'includes tiff extension' do
      expect(subject).to include 'tiff'
    end

    it 'includes png extension' do
      expect(subject).to include 'png'
    end
  end

  describe '#pattern' do
    subject { resolver.pattern(id) }

    context 'with dashes' do
      let(:id) { 'foo-bar-baz' }
      it 'accepts ids with dashes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'with colons' do
      let(:id) { 'fo:baz' }
      it 'accepts ids with colons' do
        expect { subject }.not_to raise_error
      end
    end

    context 'with slashes (unallowed by default)' do
      let(:id) { 'fo/baz' }
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'as an integer' do
      let(:id) { 1 }
      it 'converts it to a string before parsing' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
