# frozen_string_literal: true

RSpec.describe Webgl::Unity do
  let(:id) { 'validnoid' }
  let(:unity_file) { './spec/fixtures/fake-game.zip' }

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
    subject { described_class.from(id: id, file: unity_file).read(js_file) }
    let(:js_file) { "Build/thing.asm.memory.unityweb" }
    it "returns the file contents" do
      expect(subject).to eq "\u001F\x8B\b\bT\xAB\xA2Z\u0000\u0003thing.asm.memory.unityweb\u0000+K,R(\xC9\xC8\xCCK/V\xB0UP\x82\xB0\x94\xAC\xB9\u0000\xD4\xDB\xCD\xFC\u0017\u0000\u0000\u0000"
    end
  end

  describe "#file" do
    subject { described_class.from(id: id, file: unity_file).file(js_file) }
    let(:js_file) { "Build/thing.asm.memory.unityweb" }
    it "returns the file path" do
      expect(subject).to eq "./tmp/webgl/validnoid/Build/thing.asm.memory.unityweb"
    end
  end
end
