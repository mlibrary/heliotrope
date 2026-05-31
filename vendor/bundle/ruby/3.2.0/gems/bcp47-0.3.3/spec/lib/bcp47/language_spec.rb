require 'spec_helper'

describe BCP47::Language do
  let(:language) { BCP47::Language.new('de', name: 'German') }

  it "is a BCP47 Subtag" do
    language.should be_kind_of(BCP47::Subtag)
  end

  it "has a code" do
    language.code.should == 'de'
  end

  it "has a name" do
    language.name.should == 'German'
  end

  describe "#plural_rule_names" do
    it "defaults to %w(one other)" do
      language.plural_rule_names.should == BCP47::Language::DEFAULT_PLURAL_RULE_NAMES
    end

    it "is overwriteable" do
      language = BCP47::Language.new('ja', plural_rule_names: ['other'])
      language.plural_rule_names.should == ['other']
    end
  end

  describe "#direction" do
    it "defaults to 'ltr'" do
      language.direction.should == 'ltr'
    end

    it "is overwriteable" do
      language = BCP47::Language.new('ar', direction: :rtl)
      language.direction.should == :rtl
    end
  end

  describe ".identify(full_code)" do
    it "identifies from 'de'" do
      BCP47::Language.identify('de').should == BCP47::Language.new('de')
    end

    it "identifies from 'fr-CH'" do
      BCP47::Language.identify('fr-CH').should == BCP47::Language.new('fr')
    end

    it "returns nil when it can't identify" do
      BCP47::Language.identify('csb').should be_nil
    end
  end
end
