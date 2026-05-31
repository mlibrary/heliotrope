require File.expand_path("../../test_helper", __FILE__)

describe "Flipflop::StrategiesController" do
  before do
    @app = TestApp.new
  end

  after do
    @app.unload!
  end

  subject do
    Flipflop::StrategiesController.new
  end

  describe "enable?" do
    it "should return false when commit is empty" do
      subject.params = ActionController::Parameters.new(commit: "")
      assert_same subject.send(:enable?), false
    end

    it "should return false when commit is nil" do
      subject.params = ActionController::Parameters.new
      assert_same subject.send(:enable?), false
    end

    it "should return true when commit is on" do
      subject.params = ActionController::Parameters.new(commit: "on")
      assert_same subject.send(:enable?), true
    end

    it "should return true when commit is 1" do
      subject.params = ActionController::Parameters.new(commit: "1")
      assert_same subject.send(:enable?), true
    end
  end
end
