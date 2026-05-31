class TestEngine < Rails::Engine
  config.root = "lib/test_engine"

  initializer "features" do
    Flipflop::FeatureLoader.current.append(self)
  end
end
