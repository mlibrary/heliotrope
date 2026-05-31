# frozen_string_literal: true
require 'rails_helper'
require 'active_encode/spec/shared_specs'

describe ActiveEncode::EngineAdapters::PassThroughAdapter do
  around do |example|
    ActiveEncode::Base.engine_adapter = :pass_through

    Dir.mktmpdir do |dir|
      @dir = dir
      example.run
      Dir.foreach(dir) do |e|
        next if e == "." || e == ".."
        FileUtils.rm_rf(File.join(dir, e))
      end
    end

    ActiveEncode::Base.engine_adapter = :test
  end

  let!(:work_dir) { stub_const "ActiveEncode::EngineAdapters::PassThroughAdapter::WORK_DIR", @dir }
  let(:file) { "file://" + Rails.root.join('..', 'spec', 'fixtures', 'fireworks.mp4').to_s }
  let(:low_derivative) { "file://" + Rails.root.join('..', 'spec', 'fixtures', 'fireworks.low.mp4').to_s }
  let(:created_job) do
    ActiveEncode::Base.create(file, outputs: [{ label: 'low', url: low_derivative }])
  end
  let(:running_job) do
    created_job
  end
  let(:canceled_job) do
    find_encode 'cancelled-id'
  end
  let(:cancelling_job) do
    find_encode 'running-id'
  end
  let(:completed_job) { find_encode "completed-id" }
  let(:failed_job) { find_encode 'failed-id' }
  let(:completed_tech_metadata) do
    {
      audio_bitrate: 171_030,
      audio_codec: 'mp4a-40-2',
      duration: 6315.0,
      file_size: 199_160,
      frame_rate: 23.719,
      height: 110.0,
      id: "completed-id",
      url: "/home/pdinh/Downloads/videoshort.mp4",
      video_bitrate: 74_477,
      video_codec: 'avc1',
      width: 200.0
    }
  end
  let(:completed_output) { [{ id: "completed-id" }] }
  let(:failed_tech_metadata) { {} }

  it_behaves_like "an ActiveEncode::EngineAdapter"

  def find_encode(id)
    # Precreate ffmpeg output directory and files
    FileUtils.copy_entry "spec/fixtures/pass_through/#{id}", "#{work_dir}/#{id}"

    # Simulate that progress is modified later than other files
    sleep 0.1
    FileUtils.touch Dir.glob("#{work_dir}/#{id}/*.mp4")
    touch_fixture(id, "completed")
    touch_fixture(id, "cancelled")
    touch_fixture(id, "error.log")

    # Stub out system calls
    allow_any_instance_of(ActiveEncode::EngineAdapters::PassThroughAdapter).to receive(:`).and_return(1234)

    ActiveEncode::Base.find(id)
  end

  def touch_fixture(id, filename)
    FileUtils.touch("#{work_dir}/#{id}/#{filename}") if File.exist? "#{work_dir}/#{id}/#{filename}"
  end

  describe "#create" do
    subject { created_job }

    it "creates a directory whose name is the encode id" do
      expect(File).to exist("#{work_dir}/#{subject.id}")
    end

    context "input file exists" do
      it "has the input technical metadata in a file" do
        expect(File.read("#{work_dir}/#{subject.id}/input_metadata")).not_to be_empty
      end
    end

    context "input file doesn't exist" do
      let(:missing_file) { "file:///a_bogus_file.mp4" }
      let(:missing_job) { ActiveEncode::Base.create(missing_file, outputs: [{ label: "low", url: 'mp4' }]) }

      it "returns the encode with correct error" do
        expect(missing_job.errors).to include("#{missing_file} does not exist or is not accessible")
        expect(missing_job.percent_complete).to be 1
      end
    end

    context "input file is not media" do
      let(:nonmedia_file) { "file://" + Rails.root.join('Gemfile').to_s }
      let(:nonmedia_job) { ActiveEncode::Base.create(nonmedia_file, outputs: [{ label: "low", url: nonmedia_file }]) }

      it "returns the encode with correct error" do
        expect(nonmedia_job.errors).to include("Error inspecting input: #{nonmedia_file}")
        expect(nonmedia_job.percent_complete).to be 1
      end
    end

    context "input filename with spaces" do
      let(:file_with_space) { "file://" + Rails.root.join('..', 'spec', 'fixtures', 'file with space.mp4').to_s }
      let(:file_with_space_derivative) { "file://" + Rails.root.join('..', 'spec', 'fixtures', 'file with space.low.mp4').to_s }
      let!(:create_space_job) { ActiveEncode::Base.create(file_with_space, outputs: [{ label: "low", url: file_with_space_derivative }]) }
      let(:find_space_job) { ActiveEncode::Base.find create_space_job.id }

      it "does not have errors" do
        expect(find_space_job.errors).to be_empty
      end

      it "has the input technical metadata in a file" do
        expect(File.read("#{work_dir}/#{create_space_job.id}/input_metadata")).not_to be_empty
      end

      context 'when uri encoded' do
        let(:file_with_space) { URI.encode("file://" + Rails.root.join('..', 'spec', 'fixtures', 'file with space.mp4').to_s) }
        let(:file_with_space_derivative) { URI.encode("file://" + Rails.root.join('..', 'spec', 'fixtures', 'file with space.low.mp4').to_s) }

        it "does not have errors" do
          expect(find_space_job.errors).to be_empty
        end

        it "has the input technical metadata in a file" do
          expect(File.read("#{work_dir}/#{create_space_job.id}/input_metadata")).not_to be_empty
        end
      end
    end

    context 'when failed' do
      subject { created_job }

      before do
        allow_any_instance_of(Object).to receive(:`).and_raise Errno::ENOENT
      end

      it { is_expected.to be_failed }
      it { expect(subject.errors).to be_present }
    end
  end
end
