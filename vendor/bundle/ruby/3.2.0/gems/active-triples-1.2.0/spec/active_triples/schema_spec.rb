# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ActiveTriples::Schema do
  subject { described_class }

  describe ".property" do
    it "should define a property" do
      subject.property :title, :predicate => RDF::Vocab::DC.title

      property = subject.properties.first
      expect(property.name).to eq :title
      expect(property.predicate).to eq RDF::Vocab::DC.title
    end

    it 'should hold a block' do
      subject.property :title, :predicate => RDF::Vocab::DC.title do
        configure
      end
    end
  end
end
