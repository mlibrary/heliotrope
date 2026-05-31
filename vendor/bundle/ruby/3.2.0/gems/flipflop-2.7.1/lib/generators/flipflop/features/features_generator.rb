class Flipflop::FeaturesGenerator < Rails::Generators::Base
  source_root File.expand_path("../templates", __FILE__)

  def copy_features_file
    copy_file "features.rb", "config/features.rb"
  end
end
