require 'spec_helper'

describe Openseadragon::OpenStreetMap do
  subject { Openseadragon::OpenStreetMap.new }
  
  describe "#to_tilesource" do
    it "should have an id, width and height" do
      expect(subject.to_tilesource[:type]).to eq 'openstreetmaps'
    end
  end
end
