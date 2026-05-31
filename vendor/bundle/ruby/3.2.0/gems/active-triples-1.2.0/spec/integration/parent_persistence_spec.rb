# frozen_string_literal: true
require 'spec_helper'

describe "When using the ParentPersistenceStrategy" do
  context "a new child object" do
    before do
      class ParentThing < ActiveTriples::Resource
        property :child, predicate: RDF::URI('http://example.org/#child')
      end

      class ChildThing < ActiveTriples::Resource; end
    end

    subject { ParentThing.new.child.build }

    it { is_expected.not_to be_persisted }
  end
end
