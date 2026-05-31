require 'spec_helper'

describe Riiif::AkubraSystemFileResolver do
  subject { described_class.new(Rails.root.join('../spec/samples/'), 'jp2', [[0, 2], [2, 2], [4, 1]]) }
  it "raises an error when the file isn't found" do
    expect { subject.find('demo:2') }.to raise_error Riiif::ImageNotFoundError
  end

  it 'gets the jpeg2000 file' do
    file = Dir.glob(subject.pathroot + '22/7e/9/info%3Afedora%2Fdemo%3A1%2Fjp2%2Fjp2.0').first
    expect(subject.find('demo:1').path).to eq Riiif::File.new(file).path
  end
end
