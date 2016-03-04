namespace :resque do
  namespace :pool do
    desc 'Stop resque pool'
    task :stop do
      on roles(:resque_pool), in: :sequence, wait: 5 do
        # Shuts down resque_pool master if pid exists
        if test("[ -f #{shared_path}/tmp/pids/resque-pool.pid ]")
          execute "export master_pid=$(cat #{shared_path}/tmp/pids/resque-pool.pid) && kill -QUIT $master_pid"
        else
          warn 'No resque-pool pid found'
        end
      end
    end

    desc 'Start resque pool'
    task :start do
      on roles(:resque_pool), in: :sequence, wait: 10 do
        # Starts a new resque_pool master
        execute "cd #{release_path} && bundle exec resque-pool -d -E #{fetch(:rails_env)} -c config/resque-pool.yml -p #{shared_path}/tmp/pids/resque-pool.pid -e #{fetch(:resque_stderr_log)} -o #{fetch(:resque_stdout_log)}"
      end
    end

    desc 'Restart resque pool'
    task :restart do
      invoke 'resque:pool:stop'
      invoke 'resque:pool:start'
    end
  end

  # From https://github.com/sshingler/capistrano-resque/blob/master/lib/capistrano-resque/tasks/capistrano-resque.rake
  def output_redirection
    ">> #{fetch(:resque_stdout_log)} 2>> #{fetch(:resque_stderr_log)}"
  end
end
