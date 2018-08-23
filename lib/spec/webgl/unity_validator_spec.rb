# frozen_string_literal: true

RSpec.describe Webgl::UnityValidator do
  describe "with the #from_directory initializer" do
    context "and a valid webgl" do
      subject { described_class.from_directory(@root_path) }

      before do
        @noid = 'validnoid'
        @root_path = UnpackHelper.noid_to_root_path(@noid, 'webgl')
        @file = './spec/fixtures/fake-game.zip'
        UnpackHelper.unpack_webgl(@noid, @root_path, @file)
        allow(Webgl.logger).to receive(:info).and_return(nil)
      end

      after do
        FileUtils.rm_rf('./tmp/rspec_derivatives')
      end

      it "has the correct attributes" do
        expect(subject).to be_an_instance_of(described_class)
        expect(subject.id).to eq 'validnoid'
        expect(subject.progress).to eq 'TemplateData/UnityProgress.js'
        expect(subject.loader).to eq 'Build/UnityLoader.js'
        expect(subject.json).to eq 'Build/fake.json'
      end

      context "with a missing UnityProgress.js" do
        it "returns the null object" do
          allow(File).to receive(:join).and_call_original
          allow(File).to receive(:join).with(@root_path, "TemplateData", "UnityProgress.js").and_return(nil)
          allow(Webgl.logger).to receive(:info).and_return(nil)

          expect(subject).to be_an_instance_of(Webgl::UnityValidatorNullObject)
        end
      end

      context "with a missing UnityLoader.js" do
        it "returns the null object" do
          allow(File).to receive(:join).and_call_original
          allow(File).to receive(:join).with(@root_path, "Build", "UnityLoader.js").and_return(nil)
          allow(Webgl.logger).to receive(:info).and_return(nil)

          expect(subject).to be_an_instance_of(Webgl::UnityValidatorNullObject)
        end
      end

      context "with a missing unity json file" do
        it "returns the null object" do
          allow(Find).to receive(:find).and_return(nil)
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
      expect(subject.progress).to be nil
      expect(subject.loader).to be nil
      expect(subject.json).to be nil
      expect(subject.root_path).to be nil
    end
  end
end
