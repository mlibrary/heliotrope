# frozen_string_literal: true
require 'spec_helper'
require 'zencoder'
require 'json'

describe ActiveEncode::EngineAdapters::ZencoderAdapter do
  before(:all) do
    ActiveEncode::Base.engine_adapter = :zencoder
  end
  after(:all) do
    ActiveEncode::Base.engine_adapter = :test
  end

  let(:create_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_create.json'))) }

  before do
    allow(Zencoder::Job).to receive(:create).and_return(create_response)
  end

  let(:file) { "file://#{File.absolute_path('spec/fixtures/Bars_512kb.mp4')}" }

  describe "#create" do
    before do
      allow(Zencoder::Job).to receive(:details).and_return(details_response)
      allow(Zencoder::Job).to receive(:progress).and_return(progress_response)
    end

    subject { ActiveEncode::Base.create(file) }
    let(:details_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_details_create.json'))) }
    let(:progress_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_progress_create.json'))) }
    let(:create_output) { [{ id: "511404522", url: "https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20150610/c09b61e4d130ddf923f0653418a80b9c/399ae101c3f99b4f318635e78a4e587a.mp4?AWSAccessKeyId=AKIAI456JQ76GBU7FECA&Signature=GY/9LMkQAiDOrMQwS5BkmOE200s%3D&Expires=1434033527", label: nil }] }

    it { is_expected.to be_a ActiveEncode::Base }
    it { expect(subject.id).not_to be_empty }
    it { is_expected.to be_running }
    # it { expect(subject.output).to eq create_output }
    it { expect(subject.current_operations).to be_empty }
    it { expect(subject.percent_complete).to eq 0 }
    it { expect(subject.errors).to be_empty }
    it { expect(subject.created_at).to eq '2015-06-10T14:38:47Z' }
    it { expect(subject.updated_at).to eq '2015-06-10T14:38:47Z' }

    context 'input' do
      subject { ActiveEncode::Base.create(file).input }

      it { is_expected.to be_a ActiveEncode::Input }
      it { expect(subject.id).to eq "166179248" }
      it { expect(subject.url).to eq "https://archive.org/download/LuckyStr1948_2/LuckyStr1948_2_512kb.mp4" }
      it { expect(subject.width).to be_blank }
      it { expect(subject.height).to be_blank }
      it { expect(subject.frame_rate).to be_blank }
      it { expect(subject.duration).to be_blank }
      it { expect(subject.file_size).to be_blank }
      it { expect(subject.checksum).to be_blank }
      it { expect(subject.audio_codec).to be_blank }
      it { expect(subject.video_codec).to be_blank }
      it { expect(subject.audio_bitrate).to be_blank }
      it { expect(subject.video_bitrate).to be_blank }
      it { expect(subject.state).to eq :running }
      it { expect(subject.created_at).to eq "2015-06-10T14:38:47Z" }
      it { expect(subject.updated_at).to eq "2015-06-10T14:38:00Z" }
    end

    context 'output' do
      subject { output.first }
      let(:output) { ActiveEncode::Base.find('166019107').reload.output }

      it 'is an array' do
        expect(output).to be_a Array
      end
      it { is_expected.to be_a ActiveEncode::Output }
      it { expect(subject.id).to eq "511404522" }
      it { expect(subject.url).to eq "https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20150610/c09b61e4d130ddf923f0653418a80b9c/399ae101c3f99b4f318635e78a4e587a.mp4?AWSAccessKeyId=AKIAI456JQ76GBU7FECA&Signature=GY/9LMkQAiDOrMQwS5BkmOE200s%3D&Expires=1434033527" }
      it { expect(subject.label).to be_blank }
      it { expect(subject.width).to be_blank }
      it { expect(subject.height).to be_blank }
      it { expect(subject.frame_rate).to be_blank }
      it { expect(subject.duration).to be_blank }
      it { expect(subject.file_size).to be_blank }
      it { expect(subject.checksum).to be_blank }
      it { expect(subject.audio_codec).to be_blank }
      it { expect(subject.video_codec).to be_blank }
      it { expect(subject.audio_bitrate).to be_blank }
      it { expect(subject.video_bitrate).to be_blank }
      it { expect(subject.state).to eq :running }
      it { expect(subject.created_at).to eq "2015-06-10T14:38:47Z" }
      it { expect(subject.updated_at).to eq "2015-06-10T14:38:47Z" }
    end
  end

  describe "#find" do
    before do
      allow(Zencoder::Job).to receive(:details).and_return(details_response)
      allow(Zencoder::Job).to receive(:progress).and_return(progress_response)
    end

    context "a running encode" do
      subject { ActiveEncode::Base.find('166019107') }
      let(:details_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_details_running.json'))) }
      let(:progress_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_progress_running.json'))) }
      # let(:running_output) { [{ id: "510582971", url: "https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20150609/48a6907086c012f68b9ca43461280515/1726d7ec3e24f2171bd07b2abb807b6c.mp4?AWSAccessKeyId=AKIAI456JQ76GBU7FECA&Signature=vSvlxU94wlQLEbpG3Zs8ibp4MoY%3D&Expires=1433953106", label: nil }] }
      # let(:running_tech_metadata) { { audio_bitrate: "52", audio_codec: "aac", audio_channels: "2", duration: "57992", mime_type: "mpeg4", video_framerate: "29.97", height: "240", video_bitrate: "535", video_codec: "h264", width: "320" } }

      it { is_expected.to be_a ActiveEncode::Base }
      it { expect(subject.id).to eq '166019107' }
      it { is_expected.to be_running }
      # it { expect(subject.output).to eq running_output }
      it { expect(subject.current_operations).to be_empty }
      it { expect(subject.percent_complete).to eq 30.0 }
      it { expect(subject.errors).to be_empty }
      it { expect(subject.created_at).to eq '2015-06-09T16:18:26Z' }
      it { expect(subject.updated_at).to eq '2015-06-09T16:18:28Z' }

      # it { expect(subject.tech_metadata).to eq running_tech_metadata }
      context 'input' do
        subject { ActiveEncode::Base.find('166019107').input }

        it { is_expected.to be_a ActiveEncode::Input }
        it { expect(subject.id).to eq "165990056" }
        it { expect(subject.url).to eq "https://archive.org/download/LuckyStr1948_2/LuckyStr1948_2_512kb.mp4" }
        it { expect(subject.width).to eq 320 }
        it { expect(subject.height).to eq 240 }
        it { expect(subject.frame_rate).to eq 29.97 }
        it { expect(subject.duration).to eq 57_992 }
        it { expect(subject.file_size).to be_blank }
        it { expect(subject.checksum).to be_blank }
        it { expect(subject.audio_codec).to eq "aac" }
        it { expect(subject.video_codec).to eq "h264" }
        it { expect(subject.audio_bitrate).to eq 52 }
        it { expect(subject.video_bitrate).to eq 535 }
        it { expect(subject.state).to eq :completed }
        it { expect(subject.created_at).to eq "2015-06-09T16:18:26Z" }
        it { expect(subject.updated_at).to eq "2015-06-09T16:18:32Z" }
      end

      context 'output' do
        subject { output.first }
        let(:output) { ActiveEncode::Base.find('166019107').output }

        it 'is an array' do
          expect(output).to be_a Array
        end
        it { is_expected.to be_a ActiveEncode::Output }
        it { expect(subject.id).to eq "510582971" }
        it { expect(subject.url).to eq "https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20150609/48a6907086c012f68b9ca43461280515/1726d7ec3e24f2171bd07b2abb807b6c.mp4?AWSAccessKeyId=AKIAI456JQ76GBU7FECA&Signature=vSvlxU94wlQLEbpG3Zs8ibp4MoY%3D&Expires=1433953106" }
        it { expect(subject.label).to be_blank }
        it { expect(subject.width).to be_blank }
        it { expect(subject.height).to be_blank }
        it { expect(subject.frame_rate).to be_blank }
        it { expect(subject.duration).to be_blank }
        it { expect(subject.file_size).to be_blank }
        it { expect(subject.checksum).to be_blank }
        it { expect(subject.audio_codec).to be_blank }
        it { expect(subject.video_codec).to be_blank }
        it { expect(subject.audio_bitrate).to be_blank }
        it { expect(subject.video_bitrate).to be_blank }
        it { expect(subject.state).to eq :running }
        it { expect(subject.created_at).to eq "2015-06-09T16:18:26Z" }
        it { expect(subject.updated_at).to eq "2015-06-09T16:18:32Z" }
      end
    end

    context "a cancelled encode" do
      subject { ActiveEncode::Base.find('165866551') }
      let(:details_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_details_cancelled.json'))) }
      let(:progress_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_progress_cancelled.json'))) }

      it { is_expected.to be_a ActiveEncode::Base }
      it { expect(subject.id).to eq '165866551' }
      it { is_expected.to be_cancelled }
      it { expect(subject.current_operations).to be_empty }
      it { expect(subject.percent_complete).to eq 0 }
      it { expect(subject.errors).to be_empty }
      it { expect(subject.created_at).to eq '2015-06-08T20:43:23Z' }
      it { expect(subject.updated_at).to eq '2015-06-08T20:43:26Z' }

      context 'input' do
        subject { ActiveEncode::Base.find('165866551').input }

        it { is_expected.to be_a ActiveEncode::Input }
        it { expect(subject.id).to eq "165837500" }
        it { expect(subject.url).to eq "https://archive.org/download/LuckyStr1948_2/LuckyStr1948_2_512kb.mp4" }
        it { expect(subject.width).to be_blank }
        it { expect(subject.height).to be_blank }
        it { expect(subject.frame_rate).to be_blank }
        it { expect(subject.duration).to be_blank }
        it { expect(subject.file_size).to be_blank }
        it { expect(subject.checksum).to be_blank }
        it { expect(subject.audio_codec).to be_blank }
        it { expect(subject.video_codec).to be_blank }
        it { expect(subject.audio_bitrate).to be_blank }
        it { expect(subject.video_bitrate).to be_blank }
        it { expect(subject.state).to eq :cancelled }
        it { expect(subject.created_at).to eq "2015-06-08T20:43:23Z" }
        it { expect(subject.updated_at).to eq "2015-06-08T20:43:26Z" }
      end
    end

    context "a completed encode" do
      subject { ActiveEncode::Base.find('165839139') }
      let(:details_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_details_completed.json'))) }
      let(:progress_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_progress_completed.json'))) }
      let(:completed_output) { { id: "509856876", audio_bitrate: "53", audio_codec: "aac", audio_channels: "2", duration: "5000", mime_type: "mpeg4", video_framerate: "29.97", height: "240", video_bitrate: "549", video_codec: "h264", width: "320", url: "https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20150608/ebbe865f8ef1b960d7c2bb0663b88a12/0f1948dcb2fd701fba30ff21908fe460.mp4?AWSAccessKeyId=AKIAI456JQ76GBU7FECA&Signature=1LgIyl/el9E7zeyPxzd/%2BNwez6Y%3D&Expires=1433873646", label: nil } }
      # let(:completed_tech_metadata) { { audio_bitrate: "52", audio_codec: "aac", audio_channels: "2", duration: "57992", mime_type: "mpeg4", video_framerate: "29.97", height: "240", video_bitrate: "535", video_codec: "h264", width: "320" } }

      it { is_expected.to be_a ActiveEncode::Base }
      it { expect(subject.id).to eq '165839139' }
      it { is_expected.to be_completed }
      # it { expect(subject.output).to include completed_output }
      it { expect(subject.current_operations).to be_empty }
      it { expect(subject.percent_complete).to eq 100 }
      it { expect(subject.errors).to be_empty }
      it { expect(subject.created_at).to eq '2015-06-08T18:13:53Z' }
      it { expect(subject.updated_at).to eq '2015-06-08T18:14:06Z' }

      context 'input' do
        subject { ActiveEncode::Base.find('165839139').input }

        it { is_expected.to be_a ActiveEncode::Input }
        it { expect(subject.id).to eq "165810088" }
        it { expect(subject.url).to eq "https://archive.org/download/LuckyStr1948_2/LuckyStr1948_2_512kb.mp4" }
        it { expect(subject.width).to eq 320 }
        it { expect(subject.height).to eq 240 }
        it { expect(subject.frame_rate).to eq 29.97 }
        it { expect(subject.duration).to eq 57_992 }
        it { expect(subject.file_size).to be_blank }
        it { expect(subject.checksum).to be_blank }
        it { expect(subject.audio_codec).to eq "aac" }
        it { expect(subject.video_codec).to eq "h264" }
        it { expect(subject.audio_bitrate).to eq 52 }
        it { expect(subject.video_bitrate).to eq 535 }
        it { expect(subject.state).to eq :completed }
        it { expect(subject.created_at).to eq "2015-06-08T18:13:53Z" }
        it { expect(subject.updated_at).to eq "2015-06-08T18:14:06Z" }
      end

      context 'output' do
        subject { output.first }
        let(:output) { ActiveEncode::Base.find('166019107').reload.output }

        it 'is an array' do
          expect(output).to be_a Array
        end
        it { is_expected.to be_a ActiveEncode::Output }
        it { expect(subject.id).to eq "509856876" }
        it { expect(subject.url).to eq "https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20150608/ebbe865f8ef1b960d7c2bb0663b88a12/0f1948dcb2fd701fba30ff21908fe460.mp4?AWSAccessKeyId=AKIAI456JQ76GBU7FECA&Signature=1LgIyl/el9E7zeyPxzd/%2BNwez6Y%3D&Expires=1433873646" }
        it { expect(subject.label).to be_blank }
        it { expect(subject.width).to eq 320 }
        it { expect(subject.height).to eq 240 }
        it { expect(subject.frame_rate).to eq 29.97 }
        it { expect(subject.duration).to eq 5000 }
        it { expect(subject.file_size).to be_blank }
        it { expect(subject.checksum).to be_blank }
        it { expect(subject.audio_codec).to eq "aac" }
        it { expect(subject.video_codec).to eq "h264" }
        it { expect(subject.audio_bitrate).to eq 53 }
        it { expect(subject.video_bitrate).to eq 549 }
        it { expect(subject.state).to eq :completed }
        it { expect(subject.created_at).to eq "2015-06-08T18:13:53Z" }
        it { expect(subject.updated_at).to eq "2015-06-08T18:14:06Z" }
      end
    end

    context "a failed encode" do
      subject { ActiveEncode::Base.find('166079902') }
      let(:details_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_details_failed.json'))) }
      let(:progress_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_progress_failed.json'))) }
      let(:failed_tech_metadata) { { mime_type: "video/mp4", checksum: "7ae24368ccb7a6c6422a14ff73f33c9a", duration: "6314", audio_codec: "AAC", audio_channels: "2", audio_bitrate: "171030.0", video_codec: "AVC", video_bitrate: "74477.0", video_framerate: "23.719", width: "200", height: "110" } }
      let(:failed_errors) { "The file is an XML file, and doesn't contain audio or video tracks." }

      it { is_expected.to be_a ActiveEncode::Base }
      it { expect(subject.id).to eq '166079902' }
      it { is_expected.to be_failed }
      it { expect(subject.current_operations).to be_empty }
      it { expect(subject.percent_complete).to eq 0 }
      it { expect(subject.errors).to be_empty }
      it { expect(subject.created_at).to eq '2015-06-09T20:52:57Z' }
      it { expect(subject.updated_at).to eq '2015-06-09T20:53:00Z' }

      context 'input' do
        subject { ActiveEncode::Base.find('165866551').input }

        it { is_expected.to be_a ActiveEncode::Input }
        it { expect(subject.id).to eq "166050851" }
        it { expect(subject.url).to eq "s3://zencoder-customer-ingest/uploads/2015-06-09/240330/187007/682c2d90-0eea-11e5-84c9-f158f44c3d50.xml" }
        it { expect(subject.errors).to include failed_errors }
        it { expect(subject.width).to be_blank }
        it { expect(subject.height).to be_blank }
        it { expect(subject.frame_rate).to be_blank }
        it { expect(subject.duration).to be_blank }
        it { expect(subject.file_size).to be_blank }
        it { expect(subject.checksum).to be_blank }
        it { expect(subject.audio_codec).to be_blank }
        it { expect(subject.video_codec).to be_blank }
        it { expect(subject.audio_bitrate).to be_blank }
        it { expect(subject.video_bitrate).to be_blank }
        it { expect(subject.state).to eq :failed }
        it { expect(subject.created_at).to eq "2015-06-09T20:52:57Z" }
        it { expect(subject.updated_at).to eq "2015-06-09T20:53:00Z" }
      end
    end
  end

  describe "#cancel!" do
    before do
      allow(Zencoder::Job).to receive(:cancel).and_return(cancel_response)
      allow(Zencoder::Job).to receive(:details).and_return(details_response)
      allow(Zencoder::Job).to receive(:progress).and_return(progress_response)
    end

    subject { encode.cancel! }
    let(:cancel_response) { Zencoder::Response.new(code: 200) } # TODO: check that this is the correct response code for a successful cancel
    let(:details_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_details_cancelled.json'))) }
    let(:progress_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_progress_cancelled.json'))) }

    let(:encode) { ActiveEncode::Base.create(file) }
    it { is_expected.to be_a ActiveEncode::Base }
    it { expect(subject.id).to eq '165866551' }
    it { is_expected.to be_cancelled }
  end

  describe "reload" do
    before do
      allow(Zencoder::Job).to receive(:details).and_return(details_response)
      allow(Zencoder::Job).to receive(:progress).and_return(progress_response)
    end

    subject { ActiveEncode::Base.find('166019107').reload }
    let(:details_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_details_running.json'))) }
    let(:progress_response) { Zencoder::Response.new(body: JSON.parse(File.read('spec/fixtures/zencoder/job_progress_running.json'))) }
    # let(:reload_output) { [{ id: "510582971", url: "https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20150609/48a6907086c012f68b9ca43461280515/1726d7ec3e24f2171bd07b2abb807b6c.mp4?AWSAccessKeyId=AKIAI456JQ76GBU7FECA&Signature=vSvlxU94wlQLEbpG3Zs8ibp4MoY%3D&Expires=1433953106", label: nil }] }
    # let(:reload_tech_metadata) { { audio_bitrate: "52", audio_codec: "aac", audio_channels: "2", duration: "57992", mime_type: "mpeg4", video_framerate: "29.97", height: "240", video_bitrate: "535", video_codec: "h264", width: "320" } }

    it { is_expected.to be_a ActiveEncode::Base }
    it { expect(subject.id).to eq '166019107' }
    it { is_expected.to be_running }
    # it { expect(subject.output).to eq reload_output }
    it { expect(subject.current_operations).to be_empty }
    it { expect(subject.percent_complete).to eq 30.0 }
    it { expect(subject.errors).to be_empty }
    it { expect(subject.created_at).to eq '2015-06-09T16:18:26Z' }
    it { expect(subject.updated_at).to eq '2015-06-09T16:18:28Z' }

    context 'input' do
      subject { ActiveEncode::Base.find('166019107').reload.input }

      it { is_expected.to be_a ActiveEncode::Input }
      it { expect(subject.id).to eq "165990056" }
      it { expect(subject.url).to eq "https://archive.org/download/LuckyStr1948_2/LuckyStr1948_2_512kb.mp4" }
      it { expect(subject.width).to eq 320 }
      it { expect(subject.height).to eq 240 }
      it { expect(subject.frame_rate).to eq 29.97 }
      it { expect(subject.duration).to eq 57_992 }
      it { expect(subject.file_size).to be_blank }
      it { expect(subject.checksum).to be_blank }
      it { expect(subject.audio_codec).to eq "aac" }
      it { expect(subject.video_codec).to eq "h264" }
      it { expect(subject.audio_bitrate).to eq 52 }
      it { expect(subject.video_bitrate).to eq 535 }
      it { expect(subject.state).to eq :completed }
      it { expect(subject.created_at).to eq "2015-06-09T16:18:26Z" }
      it { expect(subject.updated_at).to eq "2015-06-09T16:18:32Z" }
    end

    context 'output' do
      subject { output.first }
      let(:output) { ActiveEncode::Base.find('166019107').reload.output }

      it 'is an array' do
        expect(output).to be_a Array
      end
      it { is_expected.to be_a ActiveEncode::Output }
      it { expect(subject.id).to eq "510582971" }
      it { expect(subject.url).to eq "https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20150609/48a6907086c012f68b9ca43461280515/1726d7ec3e24f2171bd07b2abb807b6c.mp4?AWSAccessKeyId=AKIAI456JQ76GBU7FECA&Signature=vSvlxU94wlQLEbpG3Zs8ibp4MoY%3D&Expires=1433953106" }
      it { expect(subject.label).to be_blank }
      it { expect(subject.width).to be_blank }
      it { expect(subject.height).to be_blank }
      it { expect(subject.frame_rate).to be_blank }
      it { expect(subject.duration).to be_blank }
      it { expect(subject.file_size).to be_blank }
      it { expect(subject.checksum).to be_blank }
      it { expect(subject.audio_codec).to be_blank }
      it { expect(subject.video_codec).to be_blank }
      it { expect(subject.audio_bitrate).to be_blank }
      it { expect(subject.video_bitrate).to be_blank }
      it { expect(subject.state).to eq :running }
      it { expect(subject.created_at).to eq "2015-06-09T16:18:26Z" }
      it { expect(subject.updated_at).to eq "2015-06-09T16:18:32Z" }
    end
  end
end
