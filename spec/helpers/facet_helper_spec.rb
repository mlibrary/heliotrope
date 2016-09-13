require 'rails_helper'

describe FacetHelper do
  describe "#exclusivity_facet" do
    it 'returns "Does not appear in book" for "yes" value' do
      assert_equal "Does not appear in book", exclusivity_facet("yes")
    end
    it 'returns "Appears in book" for "no" value' do
      assert_equal "Appears in book", exclusivity_facet("no")
    end
    it 'returns "Unknown exclusivity <value>" otherwise' do
      assert_equal 'Unknown exclusivity FOO', exclusivity_facet("FOO")
    end
  end
end
