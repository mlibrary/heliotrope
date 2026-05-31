# desc "Explaining what the task does"
# task :hydra-editor do
#   # Task goes here
# end

desc "Run rake tasks with internal test app"
namespace :hydra_editor do
  task recompile_js: [:environment] do
    within_test_app do
      system "bundle exec rake assets:clobber assets:precompile"
    end
  end
end
