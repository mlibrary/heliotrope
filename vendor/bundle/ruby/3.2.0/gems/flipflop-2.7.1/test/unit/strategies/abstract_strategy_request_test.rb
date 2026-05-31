require File.expand_path("../../../test_helper", __FILE__)

describe Flipflop::Strategies::AbstractStrategy::RequestInterceptor do
  subject do
    Class.new(ActionController::Metal) do
      class << self
        attr_accessor :request
      end

      include AbstractController::Callbacks
      include Flipflop::Strategies::AbstractStrategy::RequestInterceptor

      def index
        self.class.request = Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request
      end
    end
  end

  after do
    Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request = nil
  end

  it "should add before filter to controller" do
    filters = subject._process_action_callbacks.select { |f| f.kind == :before }
    assert_equal 1, filters.length
  end

  it "should add after filter to controller" do
    filters = subject._process_action_callbacks.select { |f| f.kind == :after }
    assert_equal 1, filters.length
  end

  it "should set request" do
    subject.action(:index).call({})
    assert_instance_of ActionDispatch::Request, subject.request
  end

  it "should clear request" do
    subject.action(:index).call({})
    assert_nil Flipflop::Strategies::AbstractStrategy::RequestInterceptor.request
  end
end
