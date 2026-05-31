require File.expand_path("../../../test_helper", __FILE__)

class Test
  def initialize(value)
    @value = value
  end
end

class Test2
  def initialize(value)
    @value = value
  end
end

describe Flipflop::Strategies::OptionsHasher do
  subject do
    Flipflop::Strategies::OptionsHasher
  end

  def hash(value)
    subject.new(value).generate
  end

  describe "with nil" do
    it "should generate stable hash" do
      assert_equal hash(nil), hash(nil)
    end
  end

  describe "with boolean" do
    it "should generate unique hash" do
      refute_equal hash(true), hash(false)
    end

    it "should generate stable hash" do
      assert_equal hash(false), hash(false)
    end
  end

  describe "with fixnum" do
    it "should generate unique hash" do
      refute_equal hash(1), hash(2)
    end

    it "should generate stable hash" do
      assert_equal hash(2), hash(2)
    end
  end

  describe "with hash" do
    it "should generate unique hash" do
      refute_equal hash(foo: 3), hash(bar: 3)
    end

    it "should generate stable hash" do
      assert_equal hash(foo: 3), hash(foo: 3)
    end
  end

  describe "with array" do
    it "should generate unique hash" do
      refute_equal hash([1, 2]), hash([1, 2, 3])
    end

    it "should generate stable hash" do
      assert_equal hash([1, 2, 3]), hash([1, 2, 3])
    end
  end

  describe "with object" do
    it "should generate unique hash" do
      refute_equal hash(Test.new([1, 2])), hash(Test.new([1, 2, 3]))
    end

    it "should generate stable hash" do
      assert_equal hash(Test.new([1, 2, 3])), hash(Test.new([1, 2, 3]))
    end
  end

  describe "with similar object of different class" do
    it "should generate unique hash" do
      refute_equal hash(Test.new([1, 2, 3])), hash(Test2.new([1, 2, 3]))
    end
  end
end
