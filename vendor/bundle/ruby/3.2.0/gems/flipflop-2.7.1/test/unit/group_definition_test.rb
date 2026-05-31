require File.expand_path("../../test_helper", __FILE__)

describe Flipflop::GroupDefinition do
  describe "with defaults" do
    subject do
      Flipflop::GroupDefinition.new(:my_key)
    end

    it "should have specified key" do
      assert_equal :my_key, subject.key
    end

    it "should have name derived from key" do
      assert_equal "my_key", subject.name
    end

    it "should have title derived from key" do
      assert_equal "My key", subject.title
    end
  end
end
