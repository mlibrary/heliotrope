require 'spec_helper'

describe BCP47::Tag do
  describe ".new(code)" do
    it "returns a tag containing the language and region" do
      tag = BCP47::Tag.new('en-MX')
      tag.language.code.should == 'en'
      tag.region.code.should   == 'MX'
    end

    it "returns a tag containing the language only" do
      tag = BCP47::Tag.new('en-XXXXXX')
      tag.language.code.should == 'en'
      tag.region.should be_nil
    end

    it "returns a tag containing the region only" do
      tag = BCP47::Tag.new('gsw-CH')
      tag.language.should be_nil
      tag.region.code.should == 'CH'
    end

    it "returns a tag containing no language or region" do
      tag = BCP47::Tag.new('csb-XXXXXX')
      tag.language.should be_nil
      tag.region.should be_nil
    end
  end

  describe "#codes" do
    it "returns an array containing each subtag's code" do
      BCP47::Tag.new('en-US').codes.should == %w(en US)
    end
  end

  describe "#subtags" do
    it "returns an array containing the language" do
      tag = BCP47::Tag.new('fr')
      tag.subtags.size.should == 1
      tag.subtags.first.should be_kind_of(BCP47::Language)
      tag.subtags.first.code.should == 'fr'
    end

    it "returns an array containing the language and the region" do
      tag = BCP47::Tag.new('fr-CH')
      tag.subtags.size.should == 2

      tag.subtags.first.should be_kind_of(BCP47::Language)
      tag.subtags.first.code.should == 'fr'

      tag.subtags.last.should be_kind_of(BCP47::Region)
      tag.subtags.last.code.should == 'CH'
    end
  end
end
