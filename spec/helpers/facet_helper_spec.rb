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

  describe "#should_collapse_facet?" do
    let(:facet_field) { Blacklight::Configuration::FacetField.new(field: "field").normalize! }

    # If blacklight changes how the collapse method works,
    # we want to detect that change.
    it 'responds to collapse method' do
      expect(facet_field.respond_to?(:collapse)).to be true
    end

    it 'not in params and not collapse' do
      allow(helper).to receive(:facet_field_in_params?).and_return(false)
      facet_field.collapse = false
      expect(helper.should_collapse_facet?(facet_field)).to be false
    end

    it 'not in params and collapse' do
      allow(helper).to receive(:facet_field_in_params?).and_return(false)
      facet_field.collapse = true
      expect(helper.should_collapse_facet?(facet_field)).to be true
    end

    it 'in params and not collapse' do
      allow(helper).to receive(:facet_field_in_params?).and_return(true)
      facet_field.collapse = false
      expect(helper.should_collapse_facet?(facet_field)).to be false
    end

    it 'in params and collapse' do
      allow(helper).to receive(:facet_field_in_params?).and_return(true)
      facet_field.collapse = true
      expect(helper.should_collapse_facet?(facet_field)).to be false
    end
  end

  describe "#facet_field_in_params?" do
    let(:facet_field) { Blacklight::Configuration::FacetField.new(field: "field").normalize! }

    ##
    # Get the values of the facet set in the blacklight query string
    # def facet_params field
    #   config = facet_configuration_for_field(field)
    #   params[:f][config.key] if params[:f]
    # end

    # @param [String] field Solr facet name
    # @return [Blacklight::Configuration::FacetField] Blacklight facet configuration for the solr field
    # def facet_configuration_for_field(field)
    #   # short-circuit on the common case, where the solr field name and the blacklight field name are the same.
    #   return facet_fields[field] if facet_fields[field] && facet_fields[field].field == field
    #
    #   # Find the facet field configuration for the solr field, or provide a default.
    #   facet_fields.values.find { |v| v.field.to_s == field.to_s } ||
    #       FacetField.new(field: field).normalize!
    # end

    it 'field is a String and NOT in params' do
      allow(helper).to receive(:facet_params).and_return(nil)
      expect(helper.facet_field_in_params?("String")).to be false
    end

    it 'field is a String and in params' do
      allow(helper).to receive(:facet_params) do |facet|
        Blacklight::Configuration::FacetField.new(field: facet).normalize!
      end
      expect(helper.facet_field_in_params?("String")).to be true
    end

    it 'field is a Symbol and NOT in params' do
      allow(helper).to receive(:facet_params).and_return(nil)
      expect(helper.facet_field_in_params?(:Symbol)).to be false
    end

    it 'field is a Symbol and in params' do
      allow(helper).to receive(:facet_params) do |facet|
        Blacklight::Configuration::FacetField.new(field: facet).normalize!
      end
      expect(helper.facet_field_in_params?(:Symbol)).to be true
    end

    it 'field is a FacetField without pivot and NOT in params' do
      allow(helper).to receive(:facet_params).and_return(nil)
      expect(helper.facet_field_in_params?(facet_field)).to be false
    end

    it 'field is a FacetField without pivot and in params' do
      allow(helper).to receive(:facet_params) do |field|
        Blacklight::Configuration::FacetField.new(field: field).normalize!
      end
      expect(helper.facet_field_in_params?(facet_field)).to be true
    end

    it 'field is a FacetField with pivot and NOT in params and pivot NOT in params' do
      facet_field[:pivot] = ["pivot"]
      allow(helper).to receive(:facet_params).and_return(nil)
      expect(helper.facet_field_in_params?(facet_field)).to be false
    end

    it 'field is a FacetField with pivot and NOT in params and pivot in params' do
      facet_field[:pivot] = ["pivot"]
      allow(helper).to receive(:facet_params) do |field|
        (field == "pivot") ? Blacklight::Configuration::FacetField.new(field: field).normalize! : nil
      end
      expect(helper.facet_field_in_params?(facet_field)).to be true
    end

    it 'field is a FacetField with pivot and in params and pivot NOT in params' do
      facet_field[:pivot] = ["pivot"]
      allow(helper).to receive(:facet_params) do |field|
        (field == "field") ? Blacklight::Configuration::FacetField.new(field: field).normalize! : nil
      end
      expect(helper.facet_field_in_params?(facet_field)).to be false
    end

    it 'field is a FacetField with pivot and in params and pivot in params' do
      facet_field[:pivot] = ["pivot"]
      allow(helper).to receive(:facet_params) do |field|
        Blacklight::Configuration::FacetField.new(field: field).normalize!
      end
      expect(helper.facet_field_in_params?(facet_field)).to be true
    end
  end
end
