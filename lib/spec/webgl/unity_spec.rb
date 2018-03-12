# frozen_string_literal: true

RSpec.describe Webgl::Unity do
  let(:id) { 'validnoid' }
  let(:unity_file) { './spec/fixtures/fake-game.unity' }

  describe "with a valid noid and unity file" do
    subject { described_class.from(id: id, file: unity_file) }

    it "has the correct attributes" do
      expect(subject).to be_an_instance_of(described_class)
      expect(subject.id).to eq 'validnoid'
      expect(subject.unity_progress).to eq 'TemplateData/UnityProgress.js'
      expect(subject.unity_loader).to eq 'Build/UnityLoader.js'
      expect(subject.unity_json).to eq 'Build/fake.json'
    end
  end

  describe "with an invalid noid" do
    subject { described_class.from(id: "bad") }
    it "is a UnityNullObject" do
      expect(subject).to be_an_instance_of(Webgl::UnityNullObject)
      expect(subject.id).to eq nil
      expect(subject.unity_progress).to eq nil
      expect(subject.unity_loader).to eq nil
      expect(subject.unity_json).to eq nil
    end
  end

  describe "#read" do
    let(:js_file) { "Build/thing.asm.memory.unityweb" }
    context "without compression" do
      subject { described_class.from(id: id, file: unity_file).read(js_file) }
      it "returns the uncompressed file contents" do
        expect(subject).to eq "var things = \"things\";\n"
      end
    end

    context "with compression" do
      subject { described_class.from(id: id, file: unity_file).read(js_file, true) }
      it "returns the compressed file contents" do
        expect(subject).to eq "\u001F\x8B\b\bT\xAB\xA2Z\u0000\u0003thing.asm.memory.unityweb\u0000+K,R(\xC9\xC8\xCCK/V\xB0UP\x82\xB0\x94\xAC\xB9\u0000\xD4\xDB\xCD\xFC\u0017\u0000\u0000\u0000"
      end
    end
  end
end
