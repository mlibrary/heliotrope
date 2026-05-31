require_relative "../lib/unicode/types"
require "minitest/autorun"

describe Unicode::Types do
  describe ".types (alias .of)" do
    it "will always return an Array" do
      assert_equal [], Unicode::Types.of("")
    end 

    it "will return all types that characters in the string belong to" do
      assert_equal ["Control", "Graphic"], Unicode::Types.of("A\tb")
    end 

    it "will return all types sorted order" do
      assert_equal ["Control", "Graphic"], Unicode::Types.of("A\t")
      assert_equal ["Control", "Graphic"], Unicode::Types.of("\tA")
    end 

    it "will call .type for every character" do
      mocked_method = Minitest::Mock.new
      mocked_method.expect :call, "first type",  ["A"]
      mocked_method.expect :call, "second type", ["2"]
      Unicode::Types.stub :type, mocked_method do
        Unicode::Types.of("A2")
      end 
      mocked_method.verify
    end 
  end

  describe ".type" do
    it "will return type for that character" do
      assert_equal "Format", Unicode::Types.type("­")
    end

    it "will return Noncharacter for codepoints defined as noncharacter" do
      assert_equal "Noncharacter", Unicode::Types.type("\u{10ffff}")
    end

    it "will return Reserved for unassigned codepoints" do
      assert_equal "Reserved", Unicode::Types.type("\u{10c50}")
      assert_equal "Reserved", Unicode::Types.type("\u{c03a6}")
    end

    it "will work with invalid surrogate values" do
      assert_equal "Surrogate", Unicode::Types.type("\xED\xA0\x80")
    end
  end

  describe ".names" do
    it "will return a list of all types" do
      assert_equal %w[ 
        Graphic
        Format
        Control
        Private-use
        Surrogate
        Noncharacter
        Reserved
      ], Unicode::Types.names
    end
  end
end

