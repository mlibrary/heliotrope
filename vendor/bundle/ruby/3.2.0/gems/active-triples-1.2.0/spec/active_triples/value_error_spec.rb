# frozen_string_literal: true
require "spec_helper"

describe ActiveTriples::Relation::ValueError do
  subject { described_class.new(value) }
  
  let(:value) { :a_value }

  it { expect(subject.message).to  be_a String }
  it { expect(subject.value).to    eq   value  }
end
