class Flipflop::RoutesGenerator < Rails::Generators::Base
  def add_route
    route %{mount Flipflop::Engine => "/flipflop"}
  end
end
