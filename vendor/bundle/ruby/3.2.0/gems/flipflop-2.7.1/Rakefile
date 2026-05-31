require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new("test" => "assets:compile") do |test|
  test.pattern = "test/**/*_test.rb"
end

Rake::TestTask.new("test:unit" => "assets:compile") do |test|
  test.pattern = "test/unit/**/*_test.rb"
end

Rake::TestTask.new("test:integration" => "assets:compile") do |test|
  test.pattern = "test/integration/**/*_test.rb"
end

task default: :test

namespace :assets do
  stylesheets_src_path = "src/stylesheets"
  stylesheets_dst_path = "app/views/flipflop/stylesheets"
  stylesheet_file = "_flipflop.css"
  stylesheet_dst_path = stylesheets_dst_path + "/" + stylesheet_file

  task :compile do
    require "bundler/setup"
    require "flipflop"
    require "sprockets"
    require "bootstrap"

    environment = Sprockets::Environment.new
    environment.append_path stylesheets_src_path
    environment.append_path Bootstrap.stylesheets_path
    environment.css_compressor = :scss
    File.write(stylesheet_dst_path, environment[stylesheet_file])
  end

  task :watch do
    require "listen"

    listener = Listen.to(stylesheets_src_path, only: /\.scss$/) do
      Rake::Task["assets:compile"].execute
    end

    $stderr.puts("Watching #{stylesheets_src_path} for changes...")

    listener.start

    Rake::Task["assets:compile"].execute
    sleep
  end
end
