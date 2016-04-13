# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.  Don't declare `role :all`, it's a meta role.
set :stage, :aws
set :rails_env, 'production'
set :branch, ENV["REVISION"] || ENV["BRANCH"] || "master"
server 'press.curationexperts.com', user: 'deploy', roles: [:web, :app, :db, :puma, :resque_pool]

set :bundle_path, '/opt/heliotrope/shared/vendor/bundle'
set :rbenv_ruby, '2.3.0'
set :rbenv_type, :user
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w(rake gem bundle ruby rails)

namespace :deploy do
  task :restart do
    on roles(:puma) do
      # This has to be enabled in visudo on the server
      execute :sudo, '/bin/systemctl', 'restart', 'heliotrope-puma'
    end
  end
  after :finishing, :compile_assets
  after :finishing, :cleanup
  after :finishing, :restart
end

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the server.

# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#
# And/or per server (overrides global)
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
