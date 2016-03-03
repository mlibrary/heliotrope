unless Rails.env.production?
  require 'rubocop/rake_task'
  desc 'Run style checker'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.requires << 'rubocop-rspec'
    task.fail_on_error = true
  end

  desc 'Run the ci build'
  task ci: [:rubocop] do
    require 'active_fedora/rake_support'
    with_test_server do
      # run the tests
      Rake::Task['db:schema:load'].invoke
      Rake::Task['spec'].invoke
    end
  end
end

