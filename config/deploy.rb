# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'heliotrope'
set :repo_url, ENV.fetch('REPO', 'https://github.com/curationexperts/heliotrope.git')
set :deploy_to, '/opt/heliotrope'

# pass a BRANCH_NAME to deploy a branch other than master
set :branch, ENV['REVISION'] || ENV['BRANCH_NAME'] || 'master'
set :passenger_restart_with_touch, true

set :scm, :git
set :format, :pretty
set :log_level, :debug
set :pty, true
set :keep_releases, 5

set :linked_files,
    %w(
      config/blacklight.yml
      config/database.yml
      config/fedora.yml
      config/redis.yml
      config/resque-pool.yml
      config/secrets.yml
      config/solr.yml
      config/puma.rb
    )

# Default value for linked_dirs is []
set :linked_dirs,
    %w(
      config/settings
      log
      tmp
    )

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

namespace :deploy do
  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
end

namespace :puma do
  task :start do
    on roles(:puma), in: :sequence, wait: 3 do
      execute 'sudo', 'systemctl', 'restart', 'heliotrope-puma'
    end
  end
end
