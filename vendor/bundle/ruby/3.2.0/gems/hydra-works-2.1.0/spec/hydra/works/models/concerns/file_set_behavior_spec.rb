require 'spec_helper'

describe Hydra::Works::FileSetBehavior do
  class IncludesFileSetBehavior < ActiveFedora::Base
    include Hydra::Works::FileSetBehavior
  end
  subject { IncludesFileSetBehavior.new }

  it 'ensures that objects will be recognized as file_sets' do
    expect(subject).to be_file_set
  end

  it 'ensures that objects will not be collections' do
    expect(subject.collection?).to be false
  end
end
