# frozen_string_literal: true

RSpec.describe Webgl::Unity do
  let(:id) { 'validnoid' }
  let(:file) { './spec/fixtures/fake-game.unity' }

  describe "with a valid noid and unity file" do
    subject { described_class.from(id: id, file: file) }

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
end
