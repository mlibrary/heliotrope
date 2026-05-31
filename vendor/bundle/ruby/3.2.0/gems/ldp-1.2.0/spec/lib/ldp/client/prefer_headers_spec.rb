require 'spec_helper'

RSpec.describe Ldp::PreferHeaders do
  let(:header_string) { "return=representation; omit=\"http://1.1.1 http://2.3/b\"; include=\"http://2.2.2\"" }
  subject { described_class.new(header_string) }

  describe "#return" do
    it "should return what's being returned" do
      expect(subject.return).to eq "representation"
    end
  end

  describe "#omit" do
    it "should return omit array" do
      expect(subject.omit).to eq ["http://1.1.1", "http://2.3/b"]
    end
  end

  describe "#include" do
    it "should return include array" do
      expect(subject.include).to eq ["http://2.2.2"]
    end
  end

  describe "#include=" do
    it "should set include" do
      subject.include = ["http://3.3.3", "http://1.1.1"]
      
      expect(subject.include).to eq ["http://3.3.3", "http://1.1.1"]
      expect(subject.to_s).to eq "return=representation; omit=\"http://1.1.1 http://2.3/b\"; include=\"http://3.3.3 http://1.1.1\""
    end
    it "should be able to set a single value" do
      subject.include = "http://3.3.3"
      expect(subject.to_s).to eq "return=representation; omit=\"http://1.1.1 http://2.3/b\"; include=\"http://3.3.3\""
    end
    context "when set to nothing" do
      it "should not serialize that value" do
        subject.include = []
        expect(subject.to_s).to eq "return=representation; omit=\"http://1.1.1 http://2.3/b\""
      end
    end
  end

  describe "#return=" do
    it "should set return" do
      subject.return = "bananas"

      expect(subject.return).to eq "bananas"
      expect(subject.to_s).to eq "return=bananas; omit=\"http://1.1.1 http://2.3/b\"; include=\"http://2.2.2\""
    end
  end

  describe "#omit=" do
    it "should set omit" do
      subject.omit = ["http://3.3.3", "http://1.1.1"]

      expect(subject.omit).to eq ["http://3.3.3", "http://1.1.1"]
      expect(subject.to_s).to eq "return=representation; omit=\"http://3.3.3 http://1.1.1\"; include=\"http://2.2.2\""
    end
    context "when set to nothing" do
      it "should not serialize that value" do
        subject.omit = []
        expect(subject.to_s).to eq "return=representation; include=\"http://2.2.2\""
      end
    end
  end
end
