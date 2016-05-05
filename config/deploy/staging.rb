# use environment variables to deploy to Michigan staging server

set :stage, :staging
set :ssh_options, auth_methods: %w(gssapi-with-mic publickey hostbased password keyboard-interactive)
set :rails_env, 'production'
set :repo_url, ENV.fetch('REPO', 'https://github.com/curationexperts/heliotrope.git')
set :deploy_to, ENV.fetch('DIR', '/opt/heliotrope')
server "#{ENV.fetch('USER')}@#{ENV.fetch('HOST')}", roles: [:web, :app, :db, :puma, :resque_pool]

# ensure umask is set to allow groups to read/write
SSHKit.config.umask = "0002"

# prevent permissions issues by using a temp dir under user's home dir
set :tmp_dir, ENV['TMP'] || '/tmp'

# for distributed architecture, specify the roles & hosts separately:
# role :web, "#{ENV.fetch('WEB_USER')}@#{ENV.fetch('WEB_HOST')}"
# role :app, "#{ENV.fetch('APP_USER')}@#{ENV.fetch('APP_HOST')}"
# role :db, "#{ENV.fetch('DB_USER')}@#{ENV.fetch('DB_HOST')}"
# role :resque_pool, "#{ENV.fetch('RESQUE_USER')}@#{ENV.fetch('RESQUE_HOST')}"

# pass a BRANCH to deploy a branch other than master
# or a REVISION to deploy a specific commit
set :branch, ENV['REVISION'] || ENV['BRANCH'] || 'master'

# settings for use on a shared staging environment using rbenv
set :default_env, 'HOME' => ENV.fetch('DIR')
set :keep_releases, 3
set :rbenv_custom_path, '/l/local/rbenv'
set :rbenv_ruby, '2.3.0'
set :rbenv_type, :system
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"

set :bundle_path, -> { shared_path.join('vendor/bundle') }
set :bundle_flags, '--quiet --deployment'

namespace :deploy do
  task :restart do
    on roles(:puma) do
      # This has to be enabled in visudo on the server
      execute :sudo, '/bin/systemctl', 'restart', 'app-heliotrope-testing'
    end
  end

  # before :starting, "linked_files:upload:files"
  after :finishing, :compile_assets
  after :finishing, :cleanup
  after :finishing, :restart
end
