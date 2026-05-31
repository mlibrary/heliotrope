require File.expand_path("../../test_helper", __FILE__)

class NullStrategy < Flipflop::Strategies::AbstractStrategy
  def enabled?(feature)
  end
end

class TrueStrategy < Flipflop::Strategies::AbstractStrategy
  def enabled?(feature)
    true
  end
end

class FalseStrategy < Flipflop::Strategies::AbstractStrategy
  def enabled?(feature)
    false
  end
end

describe Flipflop::FeatureSet do
  subject do
    Flipflop::FeatureSet.current.send(:initialize)
    Flipflop::FeatureSet.current.tap do |set|
      set.add(Flipflop::FeatureDefinition.new(:one))
    end
  end

  describe "current" do
    it "should return same instance" do
      current = subject
      assert_equal current, Flipflop::FeatureSet.current
    end

    it "should return same instance in different thread" do
      current = subject
      assert_equal current, Thread.new { Flipflop::FeatureSet.current }.value
    end
  end

  describe "test" do
    it "should freeze strategies" do
      subject.test!
      assert_raises RuntimeError do
        subject.use(Flipflop::Strategies::AbstractStrategy.new)
      end
    end

    it "should replace strategies with test strategy" do
      subject.test!
      assert_equal [Flipflop::Strategies::TestStrategy], subject.strategies.map(&:class)
    end

    it "should replace strategies with given strategy" do
      subject.test!(Flipflop::Strategies::LambdaStrategy.new)
      assert_equal [Flipflop::Strategies::LambdaStrategy], subject.strategies.map(&:class)
    end

    it "should return test strategy" do
      returned = subject.test!(strategy = Flipflop::Strategies::LambdaStrategy.new)
      assert_equal strategy, returned
    end
  end

  describe "enabled" do
    it "should return false by default" do
      subject.use(NullStrategy.new)
      assert_equal false, subject.enabled?(:one)
    end

    it "should return value of next true strategy if unknown" do
      subject.use(NullStrategy.new)
      subject.use(TrueStrategy.new)
      assert_equal true, subject.enabled?(:one)
    end

    it "should return value of next false strategy if unknown" do
      subject.use(NullStrategy.new)
      subject.use(FalseStrategy.new)
      assert_equal false, subject.enabled?(:one)
    end

    it "should stop resolving at first true value" do
      subject.use(TrueStrategy.new)
      subject.use(FalseStrategy.new)
      subject.use(NullStrategy.new)
      assert_equal true, subject.enabled?(:one)
    end

    it "should stop resolving at first false value" do
      subject.use(FalseStrategy.new)
      subject.use(TrueStrategy.new)
      subject.use(NullStrategy.new)
      assert_equal false, subject.enabled?(:one)
    end
  end

  describe "add" do
    it "should add feature" do
      subject.add(feature = Flipflop::FeatureDefinition.new(:feature))
      assert_equal feature, subject.feature(feature.key)
    end

    it "should freeze feature" do
      subject.add(feature = Flipflop::FeatureDefinition.new(:feature))
      assert subject.feature(feature.key).frozen?
    end

    it "should raise error with message if feature with same key is added" do
      subject.add(Flipflop::FeatureDefinition.new(:feature))
      error = assert_raises Flipflop::FeatureError do
        subject.add(Flipflop::FeatureDefinition.new(:feature))
      end
      assert_equal "Feature 'feature' already defined.", error.message
    end
  end

  describe "use" do
    it "should add strategy" do
      subject.use(strategy = NullStrategy.new)
      assert_equal strategy, subject.strategy(strategy.key)
    end

    it "should freeze strategy" do
      subject.use(strategy = NullStrategy.new)
      assert subject.strategy(strategy.key).frozen?
    end

    it "should raise error with message if strategy with same key is added" do
      subject.use(NullStrategy.new)
      error = assert_raises Flipflop::StrategyError do
        subject.use(NullStrategy.new)
      end
      assert_equal "Strategy 'null' (NullStrategy) already defined with identical options.", error.message
    end
  end

  describe "feature" do
    it "should raise if feature is unknown" do
      assert_raises Flipflop::FeatureError do
        subject.feature(:unknown)
      end
    end
  end

  describe "strategy" do
    it "should raise if strategy is unknown" do
      assert_raises Flipflop::StrategyError do
        subject.strategy("12345")
      end
    end
  end
end
