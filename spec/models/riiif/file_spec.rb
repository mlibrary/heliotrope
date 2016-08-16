require 'rails_helper'

# Riiif::File is taken from the riiif gem https://github.com/curationexperts/riiif
# We override it in order to use netpbn's tifftopnm for tiffs
# See #400
describe Riiif::File do
  let(:path) { File.join(fixture_path, 'kitty.tif') }
  subject { described_class.new(path) }

  describe '#mime_type' do
    context 'when file is a tiff' do
      it 'returns mime_type "image/tiff"' do
        expect(subject.mime_type(path)).to eq('image/tiff')
      end
    end
  end

  describe '#extract' do
    before { allow_any_instance_of(described_class).to receive(:execute).and_return(true) }

    context 'when netpbn is installed and the image is a tiff' do
      it 'calls extract_tifftopnm' do
        allow_any_instance_of(described_class).to receive(:mime_type).and_return('image/tiff')
        allow_any_instance_of(described_class).to receive(:find_executable).and_return('/usr/bin/tifftopnm')

        expect(subject).to receive(:extract_tifftopnm).with({})
        subject.extract({})
      end
    end

    context 'when netpbn is not installed and the image is a tiff' do
      it 'calls extract_imagemagick' do
        allow_any_instance_of(described_class).to receive(:mime_type).and_return('image/tiff')
        allow_any_instance_of(described_class).to receive(:find_executable).and_return(nil)

        expect(subject).to receive(:extract_imagemagick).with({})
        subject.extract({})
      end
    end

    context 'when netpbn is installed and the image is a jpeg' do
      it 'calls extract_imagemagick' do
        # only tiffs use netpbn for now
        allow_any_instance_of(described_class).to receive(:mime_type).and_return('image/jpg')
        allow_any_instance_of(described_class).to receive(:find_executable).and_return('usr/bin/tifftopnm')

        expect(subject).to receive(:extract_imagemagick).with({})
        subject.extract({})
      end
    end
  end

  describe "#extract_tifftopnm" do
    context "with options" do
      it "returns the command(s) to execute" do
        opts = { crop: "1024x1024+2048+4096", size: "x200", quality: 50 }
        expect(subject.extract_tifftopnm(opts)).to match(/tifftopnm -byrow #{path}/)
        expect(subject.extract_tifftopnm(opts)).to match(/pamcut 2048 4096 1024 1024/)
        expect(subject.extract_tifftopnm(opts)).to match(/pnmscalefixed -ysize 200/)
        expect(subject.extract_tifftopnm(opts)).to match(/pnmtojpeg -quality 95/)
      end
    end
  end
end
