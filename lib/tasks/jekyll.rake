namespace :jekyll do
  task build: :environment do
    dest = Rails.root.join('public')

    options = {
      'baseurl' => '',
      'config' => Rails.root.join('config', 'jekyll.yml').to_s,
      'watch' => true,
      'port' => 3000,
      'source' => Rails.root.join('fulcrum').to_s,
      'destination' => dest.to_s
    }

    build = Thread.new { Jekyll::Commands::Build.process(options) }
    serve = Thread.new { Jekyll::Commands::Serve.process(options) }

    commands = [build, serve]
    commands.each { |c| c.join }
  end

  task deploy: :environment do
    dest = Rails.root.join('public')

    options = {
      'baseurl' => '',
      'config' => Rails.root.join('config', 'jekyll.yml').to_s,
      'source' => Rails.root.join('fulcrum').to_s,
      'destination' => dest.to_s
    }

    Jekyll::Commands::Build.process(options)
  end
end
