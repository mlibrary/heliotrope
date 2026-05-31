require 'spec_helper'

describe Openseadragon::Image do
  subject { Openseadragon::Image.new id: 'some-id', width: 400, height: 500 }
  
  describe "#to_tilesource" do
    it "should have an id, width and height" do
      expect(subject.to_tilesource[:identifier]).to eq 'some-id'
      expect(subject.to_tilesource[:width]).to eq 400
      expect(subject.to_tilesource[:height]).to eq 500
    end
  end
end
