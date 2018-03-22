# frozen_string_literal: true

RSpec.describe Webgl::UnityValidator do
  describe "with a valid webgl" do
    before do
      @id = 'validnoid'
      @file = './spec/fixtures/fake-game.zip'
      Webgl::Unity.from(id: @id, file: @file)
    end

    after do
      Webgl::Unity.from(id: @id, file: @file).purge
    end

    subject { described_class.from(@id) }

    it "has the correct attributes" do
      expect(subject).to be_an_instance_of(described_class)
      expect(subject.id).to eq 'validnoid'
      expect(subject.progress).to eq 'TemplateData/UnityProgress.js'
      expect(subject.loader).to eq 'Build/UnityLoader.js'
      expect(subject.json).to eq 'Build/fake.json'
    end
  end
end
