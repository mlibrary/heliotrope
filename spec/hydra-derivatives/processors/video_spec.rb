# frozen_string_literal: true

# based on https://github.com/samvera/hydra-derivatives/blob/f781d112e05155c90d3de9c6bc05308864ecb1cf/spec/processors/video_spec.rb#L1

require 'rails_helper'

describe Hydra::Derivatives::Processors::Video::Processor do
  subject { described_class.new(file_name, directives) }

  let(:file_name) { 'foo/bar.mov' }

  describe ".config" do
    before do
      @original_config = described_class.config.dup
      described_class.config.mpeg4.codec = "-vcodec mpeg4 -acodec aac -strict -2"
    end

    after { described_class.config = @original_config }
    let(:directives) { { label: :thumb, format: "mp4", url: 'http://localhost:8983/fedora/rest/dev/1234/thumbnail' } }

    it "is configurable" do
      expect(subject)
                 .to receive(:encode_file)
                                 .with("mp4",
                                       Hydra::Derivatives::Processors::Ffmpeg::OUTPUT_OPTIONS => "-filter_complex \"scale='ceil(iw*min(1, min(1280/iw, 720/ih))/2)*2':-2\" -vcodec mpeg4 -acodec aac -strict -2 -g 30 -b:v 1200k -ac 2 -ab 192k -ar 44100",
                                       Hydra::Derivatives::Processors::Ffmpeg::INPUT_OPTIONS => "")
      subject.process
    end
  end

  context "when arguments are passed as a hash" do
    context "when a jpg thumbnail is requested" do
      let(:directives) { { label: :thumbnail, format: 'jpg', url: 'thumbnail_derivative_file_path' } }

      it "creates a derivative file" do
        expect(subject)
            .to receive(:encode_file)
                    .with("jpg",
                          Hydra::Derivatives::Processors::Ffmpeg::OUTPUT_OPTIONS => "-filter_complex scale=320:-1 -vcodec mjpeg -vframes 1 -an -f rawvideo",
                          Hydra::Derivatives::Processors::Ffmpeg::INPUT_OPTIONS => "-itsoffset -5")
        subject.process
      end
    end

    context "when a jpg video poster is requested" do
      let(:directives) { { label: :jpeg, format: 'jpg', url: 'jpeg_derivative_file_path' } }

      it "creates a derivative file" do
        expect(subject)
            .to receive(:encode_file)
                    .with("jpg",
                          Hydra::Derivatives::Processors::Ffmpeg::OUTPUT_OPTIONS => "-filter_complex \"scale='ceil(iw*min(1, min(1280/iw, 720/ih))/2)*2':-2\" -vcodec mjpeg -vframes 1 -an -f rawvideo",
                          Hydra::Derivatives::Processors::Ffmpeg::INPUT_OPTIONS => "-itsoffset -5")
        subject.process
      end
    end

    context "when a mp4 playback derivative is requested" do
      let(:directives) { { label: :mp4, format: 'mp4', url: 'mp4_derivative_file_path' } }

      it "creates a derivative file" do
        expect(subject)
            .to receive(:encode_file)
                    .with("mp4",
                          Hydra::Derivatives::Processors::Ffmpeg::OUTPUT_OPTIONS => "-filter_complex \"scale='ceil(iw*min(1, min(1280/iw, 720/ih))/2)*2':-2\" -vcodec libx264 -acodec aac -g 30 -b:v 1200k -ac 2 -ab 192k -ar 44100",
                          Hydra::Derivatives::Processors::Ffmpeg::INPUT_OPTIONS => "")
        subject.process
      end
    end

    context "when a webm playback derivative is requested" do
      let(:directives) { { label: :webm, format: 'webm', url: 'webm_derivative_file_path' } }

      it "creates a derivative file" do
        expect(subject)
            .to receive(:encode_file)
                    .with("webm",
                          Hydra::Derivatives::Processors::Ffmpeg::OUTPUT_OPTIONS => "-filter_complex \"scale='ceil(iw*min(1, min(1280/iw, 720/ih))/2)*2':-2\" -vcodec libvpx -acodec libvorbis -g 30 -b:v 1200k -ac 2 -ab 192k -ar 44100",
                          Hydra::Derivatives::Processors::Ffmpeg::INPUT_OPTIONS => "")
        subject.process
      end
    end

    context "when an unknown format is requested" do
      let(:directives) { { label: :thumb, format: 'nocnv', url: 'http://localhost:8983/fedora/rest/dev/1234/thumbnail' } }

      it "raises an ArgumentError" do
        expect { subject.process }.to raise_error ArgumentError, "Unknown format `nocnv'"
      end
    end
  end
end
