require 'spec_helper'

RSpec.describe Riiif::Image do
  subject(:image) { described_class.new('world') }

  let(:root) { File.expand_path(::File.join(::File.dirname(__FILE__), '../../..')) }
  let(:base_path) { ::File.join(root, 'spec/samples') }
  let(:resolver) { Riiif::FileSystemFileResolver.new(base_path: base_path) }
  let(:filename) { File.expand_path('spec/samples/world.jp2') }

  before do
    described_class.file_resolver = resolver
    Riiif::Image.cache.clear
  end

  describe 'happy path' do
    before do
      allow(image.info_service).to receive(:call).and_return({})
    end

    it 'renders' do
      expect(Riiif::CommandRunner).to receive(:execute)
        .with("convert -quality 85 -sampling-factor 4:2:0 -strip \'#{filename}\' jpg:-")
        .and_return('imagedata')

      expect(subject.render('size' => 'full', format: 'jpg')).to eq 'imagedata'
    end
  end

  it 'is able to override the file used for the Image' do
    allow(Riiif::CommandRunner).to receive(:execute)
      .with("identify -format '%h %w %m %[channels]' \'#{filename}[0]\'").and_return('400 800')

    img = described_class.new('some_id', Riiif::File.new(filename))
    expect(img.id).to eq 'some_id'
    expect(img.info).to eq Riiif::ImageInformation.new(width: 800, height: 400)
  end

  describe 'info' do
    it 'returns the data' do
      allow(Riiif::CommandRunner).to receive(:execute)
        .with("identify -format '%h %w %m %[channels]' \'#{filename}[0]\'").and_return('400 800')

      expect(subject.info).to eq Riiif::ImageInformation.new(width: 800, height: 400)
    end
  end

  context 'using HttpFileResolver' do
    before do
      described_class.file_resolver = Riiif::HttpFileResolver.new
      described_class.file_resolver.id_to_uri = lambda do |id|
        "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/#{id}.jpg/600px-#{id}.jpg"
      end
    end
    after do
      described_class.file_resolver = resolver
    end

    describe 'get info' do
      subject { described_class.new('Cave_26,_Ajanta') }
      it 'is easy' do
        expect(subject.info).to eq Riiif::ImageInformation.new(width: 600, height: 390)
      end
    end

    context 'when the rendered image is in the cache' do
      subject { described_class.new('Cave_26,_Ajanta') }
      before { allow(Riiif::Image.cache).to receive(:fetch).and_return('expected') }

      it 'does not fetch the file' do
        expect(described_class.file_resolver).not_to receive(:find)
        expect(subject.render(region: 'full', format: 'png')).to eq 'expected'
      end
    end
  end

  describe '#render' do
    before do
      allow(Riiif::CommandRunner).to receive(:execute)
        .with("identify -format '%h %w %m %[channels]' \'#{filename}[0]\'").and_return('131 175 JPEG')
    end

    describe 'region' do
      subject(:render) { image.render(region: region, format: 'png') }

      context 'when specifing full size' do
        let(:region) { 'full' }

        it 'returns the original' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'when specifing absolute geometry' do
        let(:region) { '80,15,60,75' }

        it 'runs the correct imagemagick command' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -crop 60x75+80+15 -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'when specifing percent geometry' do
        let(:region) { 'pct:10,10,80,70' }

        it 'runs the correct imagemagick command' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -crop 80.0%x70.0+18+13 -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'when specifing square geometry' do
        let(:region) { 'square' }

        it 'runs the correct imagemagick command' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -crop 131x131+22+0 -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'when the geometry is invalid' do
        let(:region) { '150x75' }

        it 'raises an error' do
          expect { render }.to raise_error IIIF::Image::InvalidAttributeError
        end
      end
    end

    describe 'resize' do
      subject(:render) { image.render(size: size, format: 'png') }

      context 'when specifing full size' do
        let(:size) { 'full' }

        it 'returns the original' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'when specifing percent size' do
        let(:size) { 'pct:50' }

        it 'runs the correct imagemagick command' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -resize 50.0% -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'when specifing float percent size' do
        let(:size) { 'pct:12.5' }

        it 'runs the correct imagemagick command' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -resize 12.5% -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'when specifing w, size' do
        let(:size) { '50,' }

        it 'runs the correct imagemagick command' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -resize 50 -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'when specifing ,h size' do
        let(:size) { ',50' }

        it 'runs the correct imagemagick command' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -resize x50 -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'when specifing w,h size' do
        let(:size) { '150,75' }

        it 'runs the correct imagemagick command' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -resize 150x75! -strip \'#{filename}\' png:-")
          render
        end
      end
      context 'when specifing bestfit (!w,h) size' do
        let(:size) { '!150,75' }

        it 'runs the correct imagemagick command' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -resize 150x75 -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'when the geometry is invalid' do
        let(:size) { '150x75' }

        it 'raises an error' do
          expect { render }.to raise_error IIIF::Image::InvalidAttributeError
        end
      end
    end

    describe 'rotate' do
      subject(:render) { image.render(rotation: rotation, format: 'png') }

      context 'without rotating' do
        let(:rotation) { '0' }

        it 'returns the original' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'with a float value' do
        let(:rotation) { '22.5' }

        it 'handles floats' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -virtual-pixel white +distort srt 22.5 -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'with an invalid value' do
        let(:rotation) { '150x' }

        it 'raises an error for invalid angle' do
          expect { render }.to raise_error IIIF::Image::InvalidAttributeError
        end
      end
    end

    describe 'quality' do
      subject(:render) { image.render(quality: quality, format: 'png') }

      context 'when default is specified' do
        let(:quality) { 'default' }

        it 'returns the original when specifing default' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'when color is specified' do
        let(:quality) { 'color' }

        it 'returns the original when specifing color' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'when grey is specified' do
        let(:quality) { 'grey' }

        it 'converts to grayscale' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -colorspace Gray -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'when bitonal is specified' do
        let(:quality) { 'bitonal' }

        it 'converts to bitonal' do
          expect(Riiif::CommandRunner).to receive(:execute)
            .with("convert -colorspace Gray -type Bilevel -strip \'#{filename}\' png:-")
          render
        end
      end

      context 'when an invalid quality is specified' do
        let(:quality) { 'best' }

        it 'raises an error' do
          expect { render }.to raise_error IIIF::Image::InvalidAttributeError
        end
      end
    end
  end
end
