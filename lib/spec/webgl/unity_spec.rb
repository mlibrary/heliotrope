# frozen_string_literal: true

RSpec.describe Webgl::Unity do
  context "using #from_directory with root_path" do
    before do
      @noid = 'validnoid'
      @root_path = UnpackHelper.noid_to_root_path(@noid, 'webgl')
      @file = './spec/fixtures/fake-game.zip'
      UnpackHelper.unpack_webgl(@noid, @root_path, @file)
      allow(Webgl.logger).to receive(:info).and_return(nil)
    end

    after do
      FileUtils.rm_rf(Dir[File.join('./tmp', 'rspec_derivatives')])
    end

    describe "with a valid noid and unity file" do
      subject { described_class.from_directory(@root_path) }

      it "has the correct attributes" do
        expect(subject).to be_an_instance_of(described_class)
        expect(subject.id).to eq 'validnoid'
        expect(subject.unity_progress).to eq 'TemplateData/UnityProgress.js'
        expect(subject.unity_loader).to eq 'Build/UnityLoader.js'
        expect(subject.unity_json).to eq 'Build/fake.json'
        expect(subject.root_path).to eq @root_path
      end
    end

    describe "with an invalid noid" do
      subject { described_class.from_directory("/not/a/real/path") }
      it "is a UnityNullObject" do
        expect(subject).to be_an_instance_of(Webgl::UnityNullObject)
        expect(subject.id).to eq nil
        expect(subject.unity_progress).to eq nil
        expect(subject.unity_loader).to eq nil
        expect(subject.unity_json).to eq nil
        expect(subject.root_path).to eq nil
      end
    end

    describe "#file" do
      subject { described_class.from_directory(@root_path).file(js_file) }
      let(:js_file) { "Build/thing.asm.memory.unityweb" }
      it "returns the file path" do
        expect(subject).to eq "./tmp/rspec_derivatives/va/li/dn/oi/d-webgl/Build/thing.asm.memory.unityweb"
      end
    end
  end
end
