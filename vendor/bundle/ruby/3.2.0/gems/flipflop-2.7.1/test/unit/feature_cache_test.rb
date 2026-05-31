require File.expand_path("../../test_helper", __FILE__)

describe Flipflop::FeatureCache do
  subject do
    Flipflop::FeatureCache.current
  end

  after do
    Flipflop::FeatureCache.current.disable!
  end

  describe "current" do
    it "should return same instance" do
      current = subject
      assert_equal current, Flipflop::FeatureCache.current
    end

    it "should return new instance in different thread" do
      current = subject
      refute_equal current, Thread.new { Flipflop::FeatureCache.current }.value
    end
  end

  describe "when enabled" do
    before do
      subject.enable!
    end

    describe "enabled" do
      it "should return true" do
        assert_equal true, subject.enabled?
      end
    end

    describe "fetch" do
      it "should store value by key" do
        subject.fetch(:key) { 1 }
        assert_equal 1, subject.fetch(:key) { 2 }
      end

      it "should not call block if cached" do
        called = false
        subject.fetch(:key) { 1 }
        subject.fetch(:key) { called = true }
        assert_equal false, called
      end
    end

    describe "clear" do
      it "should empty cache" do
        subject.fetch(:key) { 1 }
        subject.clear!
        assert_equal 2, subject.fetch(:key) { 2 }
      end
    end
  end

  describe "when disabled" do
    before do
      subject.disable!
    end

    describe "enabled" do
      it "should return false" do
        assert_equal false, subject.enabled?
      end
    end

    describe "fetch" do
      it "should not store value" do
        subject.fetch(:key) { 1 }
        assert_equal 2, subject.fetch(:key) { 2 }
      end

      it "should always call block" do
        called = false
        subject.fetch(:key) { 1 }
        subject.fetch(:key) { called = true }
        assert_equal true, called
      end
    end
  end

  describe "enable" do
    it "should not clear cache" do
      subject.enable!
      subject.fetch(:key) { 1 }
      subject.enable!
      assert_equal 1, subject.fetch(:key) { 2 }
    end
  end

  describe "disable" do
    it "should clear cache" do
      subject.enable!
      subject.fetch(:key) { 1 }
      subject.disable!
      subject.enable!
      assert_equal 2, subject.fetch(:key) { 2 }
    end
  end

  describe "middleware" do
    subject do
      app = ->(env) {
        raise env["error"] if env["error"]
        env["cache"] = Flipflop::FeatureCache.current.enabled?
        return [200, {}, ["ok"]]
      }
      Flipflop::FeatureCache::Middleware.new(app)
    end

    it "should call app" do
      response = subject.call({})
      assert_equal "ok", response[2].to_a.join
    end

    it "should enable cache before request" do
      response = subject.call(env = {})
      response[2].try(:close)
      assert_equal true, env["cache"]
    end

    it "should disable cache after request" do
      response = subject.call({})
      response[2].try(:close)
      assert_equal false, Flipflop::FeatureCache.current.enabled?
    end

    it "should disable cache after error" do
      subject.call({ "error" => "boo!" }) rescue nil
      assert_equal false, Flipflop::FeatureCache.current.enabled?
    end

    it "should not change cache if already enabled" do
      Flipflop::FeatureCache.current.enable!
      response = subject.call({})
      response[2].try(:close)
      assert_equal true, Flipflop::FeatureCache.current.enabled?
    end
  end
end
