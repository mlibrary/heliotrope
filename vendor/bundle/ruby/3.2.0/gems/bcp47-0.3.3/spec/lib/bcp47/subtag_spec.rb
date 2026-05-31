require 'spec_helper'

class Subtag < BCP47::Subtag
  DEFINITIONS_FILE = "spec/fixtures/base.yml"
  DEFAULT_CODE     = "fr"
private
  def i18n_scope
    super << ".languages"
  end
end

describe BCP47::Subtag do
  describe "#==(object)" do
    it "returns true when both have the same code" do
      BCP47::Region.find('SY').should == BCP47::Region.find('SY')
    end

    it "returns false when they have different codes" do
      BCP47::Region.find('FR').should_not == BCP47::Region.find('GB')
    end
  end

  describe "#full_name" do
    it "is composed of the code and the name" do
      full_name = Subtag.find('fr').full_name
      full_name.should match(/fr/)
      full_name.should match(/French/)
    end
  end

  describe ".all" do
    it "gets its definition from the DEFINITIONS_FILE" do
      subtags = Subtag.all
      subtags[0].should == Subtag.find('en')
      subtags[1].should == Subtag.find('fr')
      subtags[2].should == Subtag.find('de')
    end
  end

  describe ".find(code)" do
    it "finds a subtag by code" do
      subtag = Subtag.find('de')
      subtag.code.should == 'de'
      subtag.name.should == 'German'
    end

    it "returns nil when no language can be found" do
      Subtag.find('xxxx').should be_nil
    end
  end

  describe ".default" do
    it "finds from DEFAULT_CODE" do
      Subtag.default.should == Subtag.find('fr')
    end
  end

  describe ".codes" do
    it "returns an array of all codes" do
      Subtag.codes.should == %w(en fr de)
    end
  end
end
