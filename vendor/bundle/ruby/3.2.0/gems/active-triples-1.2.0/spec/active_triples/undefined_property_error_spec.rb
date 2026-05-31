# frozen_string_literal: true
require "spec_helper"

describe ActiveTriples::UndefinedPropertyError do
  subject { described_class.new(property, klass) }
  
  let(:property) { :a_property }
  let(:klass)    { :a_class }

  it { expect(subject.message).to  be_a String }
  
  it { expect(subject.property).to eq property }
  it { expect(subject.klass).to    eq klass }
end
  
