# frozen_string_literal: true

RSpec.describe Webgl::UnityValidator do
  describe "with the #from_directory initializer" do
    context "and a valid webgl" do
      subject { described_class.from_directory(@root_path) }

      before do
        @noid = 'validnoid'
        @root_path = UnpackHelper.noid_to_root_path(@noid, 'webgl')
        # using the fake-game from the main fixtures directory
        @file = '../spec/fixtures/fake-game.zip'
        UnpackHelper.unpack_webgl(@noid, @root_path, @file)
        allow(Webgl.logger).to receive(:info).and_return(nil)
      end

      after do
        FileUtils.rm_rf('./tmp/rspec_derivatives')
      end

      it "has the correct attributes" do
        expect(subject).to be_an_instance_of(described_class)
        expect(subject.id).to eq 'validnoid'
        expect(subject.loader).to eq 'validnoid/Build/blah.loader.js'
        expect(subject.data).to eq 'validnoid/Build/blah.data'
        expect(subject.framework).to eq 'validnoid/Build/blah.framework.js'
        expect(subject.code).to eq 'validnoid/Build/blah.wasm'
      end

      context "with a missing TemplateData folder" do
        it "returns the null object" do
          allow(Dir).to receive(:exist?).and_call_original
          allow(Dir).to receive(:exist?).with(File.join(@root_path, "TemplateData")).and_return(false)
          allow(Webgl.logger).to receive(:info).and_return(nil)

          expect(subject).to be_an_instance_of(Webgl::UnityValidatorNullObject)
        end
      end

      context "with a missing Build folder" do
        it "returns the null object" do
          allow(Dir).to receive(:exist?).and_call_original
          allow(Dir).to receive(:exist?).with(File.join(@root_path, "Build")).and_return(false)
          allow(Webgl.logger).to receive(:info).and_return(nil)

          expect(subject).to be_an_instance_of(Webgl::UnityValidatorNullObject)
        end
      end

      context "with a missing loader file" do
        it "returns the null object" do
          allow(Pathname).to receive(:glob).and_call_original
          allow(Pathname).to receive(:glob).with(File.join(@root_path, "Build", "*.loader.js")).and_return([])
          allow(Webgl.logger).to receive(:info).and_return(nil)

          expect(subject).to be_an_instance_of(Webgl::UnityValidatorNullObject)
        end
      end

      context "with a missing data file" do
        it "returns the null object" do
          allow(Pathname).to receive(:glob).and_call_original
          allow(Pathname).to receive(:glob).with(File.join(@root_path, "Build", "*.data")).and_return([])
          allow(Webgl.logger).to receive(:info).and_return(nil)

          expect(subject).to be_an_instance_of(Webgl::UnityValidatorNullObject)
        end
      end

      context "with a missing framework file" do
        it "returns the null object" do
          allow(Pathname).to receive(:glob).and_call_original
          allow(Pathname).to receive(:glob).with(File.join(@root_path, "Build", "*.framework.js")).and_return([])
          allow(Webgl.logger).to receive(:info).and_return(nil)

          expect(subject).to be_an_instance_of(Webgl::UnityValidatorNullObject)
        end
      end

      context "with a missing WASM/code file" do
        it "returns the null object" do
          allow(Pathname).to receive(:glob).and_call_original
          allow(Pathname).to receive(:glob).with(File.join(@root_path, "Build", "*.wasm")).and_return([])
          allow(Webgl.logger).to receive(:info).and_return(nil)

          expect(subject).to be_an_instance_of(Webgl::UnityValidatorNullObject)
        end
      end
    end

    context "with an invalid webgl" do
      subject { described_class.from_directory('/not/a/real/path') }

      it "is a null object" do
        expect(subject).to be_an_instance_of(Webgl::UnityValidatorNullObject)
      end
    end
  end

  describe "#null_object" do
    subject { described_class.null_object }

    it "is a null object" do
      expect(subject).to be_an_instance_of(Webgl::UnityValidatorNullObject)
      # The fact that these all default to nil sort of defeats the purpose of
      # a null object. TODO: if this becomes a problem, give these default values
      expect(subject.id).to be 'webglnull'
      expect(subject.loader).to eq nil
      expect(subject.data).to eq nil
      expect(subject.framework).to eq nil
      expect(subject.code).to eq nil
      expect(subject.root_path).to be nil
    end
  end
end
