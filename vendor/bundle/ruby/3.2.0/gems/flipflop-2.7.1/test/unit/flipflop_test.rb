require File.expand_path("../../test_helper", __FILE__)

describe Flipflop do
  before do
    Flipflop::FeatureSet.current.replace do
      Flipflop.configure do
        feature :one, default: true
        feature :two, default: false
      end
    end
  end

  describe "replace" do
    before do
      Flipflop::FeatureSet.current.replace do
        Flipflop.configure do
          feature :config_feature, default: true
        end
      end
    end

    it "should reset feature set" do
      Flipflop::FeatureSet.current.replace
      assert_equal [], Flipflop::FeatureSet.current.features
    end

    it "should add features" do
      assert_equal [:config_feature],
        Flipflop::FeatureSet.current.features.map(&:key)
    end

    it "should freeze features" do
      assert_raises RuntimeError do
        Flipflop::FeatureSet.current.add(Flipflop::FeatureDefinition.new(:foo))
      end
    end

    it "should freeze strategies" do
      assert_raises RuntimeError do
        Flipflop::FeatureSet.current.use(Flipflop::Strategies::AbstractStrategy.new)
      end
    end
  end

  describe "enabled?" do
    it "should return true for enabled features" do
      assert_equal true, Flipflop.on?(:one)
    end

    it "should return false for disabled features" do
      assert_equal false, Flipflop.on?(:two)
    end

    it "should call strategy once if cached" do
      called = 0
      counter = Class.new(Flipflop::Strategies::AbstractStrategy) do
        define_method :enabled? do |feature|
          called += 1
          false
        end
      end

      Flipflop::FeatureSet.current.replace do
        Flipflop.configure do
          strategy counter
          feature :one, default: true
        end
      end

      begin
        Flipflop::FeatureCache.current.enable!
        Flipflop.on?(:one)
        Flipflop.on?(:one)
        assert_equal 1, called
      ensure
        Flipflop::FeatureCache.current.disable!
      end
    end
  end

  describe "dynamic predicate method" do
    it "should respond to feature predicate" do
      assert Flipflop.respond_to?(:one?)
    end

    it "should not respond to incorrectly formatted predicate" do
      refute Flipflop.respond_to?(:foobar!)
    end

    it "should return true for enabled features" do
      assert_equal true, Flipflop.one?
    end

    it "should return false for disabled features" do
      assert_equal false, Flipflop.two?
    end

    it "raises error for incorrectly formatted predicate" do
      assert_raises NoMethodError do
        Flipflop.foobar!
      end
    end
  end
end
