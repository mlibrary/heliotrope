require 'spec_helper'

describe BCP47::Region do
  let(:region) { BCP47::Region.new('FR', name: 'France') }

  it "is a BCP47 Subtag" do
    region.should be_kind_of(BCP47::Subtag)
  end

  it "has a code" do
    region.code.should == 'FR'
  end

  it "has a name" do
    region.name.should == 'France'
  end

  describe ".identify(full_code)" do
    it "identifies from 'fr-CH'" do
      BCP47::Region.identify('fr-CH').should == BCP47::Region.find('CH')
    end

    it "identifies from 'es_MX" do
      BCP47::Region.identify('es_MX').should == BCP47::Region.find('MX')
    end

    it "returns nil when it can't identify" do
      BCP47::Region.identify('gsw').should be_nil
    end
  end
end
