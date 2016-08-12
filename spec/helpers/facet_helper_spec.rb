require 'rails_helper'

describe FacetHelper do
  describe "#exclusivity_facet" do
    it 'returns "Does not appear in book" for "P" value' do
      assert_equal "Does not appear in book", exclusivity_facet("P")
    end
    it 'returns "Appears in book" for "BP" value' do
      assert_equal "Appears in book", exclusivity_facet("BP")
    end
    it 'returns "Unknown exclusivity <value>" otherwise' do
      assert_equal 'Unknown exclusivity PBP', exclusivity_facet("PBP")
    end
  end
end
