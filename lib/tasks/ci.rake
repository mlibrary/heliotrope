unless Rails.env.production?
  desc 'Run the ci build'
  task :ci do
    require 'active_fedora/rake_support'
    with_test_server do
      # run the tests
      Rake::Task['db:schema:load'].invoke
      Rake::Task['spec'].invoke
    end
  end
end

