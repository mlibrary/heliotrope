# frozen_string_literal: true

unless Rails.env.production?
  require 'rubocop/rake_task'
  desc 'Run style checker'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.requires << 'rubocop-rspec'
    task.fail_on_error = true
  end

  require 'ruumba/rake_task'
  desc "Run style checker's sidekick"
  Ruumba::RakeTask.new(:ruumba) do |task|
    task.dir = ["app/views"]
    task.options = { tmp_folder: "ruumba", arguments: ["--display-cop-names", "--config .ruumba.yml"] }
  end

  desc "Run lib directory specs"
  task :lib_spec do
    puts 'Running specs in lib ...'
    Dir.chdir('lib') do
      RSpec::Core::RakeTask.new(:spec_lib)
      Rake::Task['spec_lib'].invoke
    end
  end

  require 'solr_wrapper'
  desc "Run solr directory specs"
  task :solr_spec do
    puts 'Running specs in solr ...'
    Dir.chdir('solr') do
      SolrWrapper.wrap do |solr|
        solr.with_collection(name: "hydra-test") do
          RSpec::Core::RakeTask.new(:spec_solr)
          Rake::Task['spec_solr'].invoke
        end
      end
    end
  end

  desc 'Run the ci build'
  task ci: %i[rubocop ruumba lib_spec solr_spec] do
    require 'active_fedora/rake_support'
    with_test_server do
      # run the tests
      Rake::Task['spec'].invoke
    end
  end

  #
  # The testing directory specs run against heliotrope-testing on nectar
  #
  desc "Run testing directory specs"
  task :testing_spec do
    puts 'Running specs in testing ...'
    Dir.chdir('testing') do
      RSpec::Core::RakeTask.new(:spec_testing)
      Rake::Task['spec_testing'].invoke
    end
  end
end
