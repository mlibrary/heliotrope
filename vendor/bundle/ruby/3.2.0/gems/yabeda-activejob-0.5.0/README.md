# Yabeda::ActiveJob
[![Gem Version](https://badge.fury.io/rb/yabeda-activejob.svg)](https://badge.fury.io/rb/yabeda-activejob)
![Tests](https://github.com/Fullscript/yabeda-activejob/actions/workflows/test.yml/badge.svg)
![Rubocop](https://github.com/Fullscript/yabeda-activejob/actions/workflows/lint.yml/badge.svg)

Yabeda metrics around rails activejobs. The motivation came from wanting something similar to [yabeda-sidekiq](https://github.com/yabeda-rb/yabeda-sidekiq) for
resque but decided to generalize even more with just doing it on the activejob level since that is likely more in use
than just resque. and could implement a lot of the general metrics needed without having to leverage the adapter
implementation and, oh the redis calls. 

Sample [Grafana dashboard](https://grafana.com/grafana/dashboards/17303) ID: [17303](https://grafana.com/grafana/dashboards/17303)

The intent is to have this plugin with an exporter such as [prometheus](https://github.com/yabeda-rb/yabeda-prometheus).

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'yabeda-activejob'
# Then add monitoring system adapter, e.g.:
# gem 'yabeda-prometheus'
```

And then execute:

    $ bundle
### Registering metrics on server process start
Depending on your activejob adapter the installation process may be different for you. If using sidekiq:
```ruby
# config/initializers/sidekiq or elsewhere
Sidekiq.configure_server do |_config|
    Yabeda::ActiveJob.install!
end
```

If using with resque:
```ruby
# config/initializers/yabeda.rb or elsewhere
Yabeda::ActiveJob.install!
```
If using resque you may need to use [yabeda-prometheus-mmap](https://github.com/yabeda-rb/yabeda-prometheus-mmap) or set your storage type to direct file store so that the metrics are available
to your collector. 

To set your storage type to direct file store you can do the following in your yabeda initializer: 

```ruby
# config/initializers/yabeda.rb or elsewhere
Prometheus::Client.config.data_store = Prometheus::Client::DataStores::DirectFileStore.new(dir: "/tmp")
```

**Note** if using direct file datastore it must be called before registering any metrics. 

If using `resque` with prometheus and scraping your resque process via the `/metrics` endpoint is unfeasible consider setting up a
push gateway. Once set up, you can use the `after_event_block` to push metrics to your push gateway after every event is
complete.

````ruby
Yabeda.configure do
   Yabeda::ActiveJob.after_event_block = Proc.new do |event|
      # do your pushing or any custom code here
   end
   Yabeda::ActiveJob.install!
end
````

**Note**: Since the notifications are registered on install make sure to setup your after_event_block before calling install!

## Metrics

- Total enqueued jobs: `activejob.enqueued_total` segmented by: queue, activejob(job class name), executions(number of executions)
- Total jobs processed: `activejob.executed_total` segmented by: queue, activejob(job class name), executions(number of executions)
- Total successful jobs processed: `activejob.success_total` segmented by: queue, activejob(job class name), executions(number of executions)
- Total failed jobs processed: `activejob.failed_total` segmented by: queue, activejob(job class name), executions(number of executions), failure_reason(error class)
- Job runtime: `activejob.runtime` (in seconds)
- Job latency: `activejob.latency` (in seconds)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Fullscript/yabeda-activejob.

### Releasing

1. Bump version number in `lib/yabeda/activejob/version.rb`

   In case of pre-releases keep in mind [rubygems/rubygems#3086](https://github.com/rubygems/rubygems/issues/3086) and check version with command like `Gem::Version.new(Yabeda::ActiveJob::VERSION).to_s`

2. Fill `CHANGELOG.md` with missing changes, add header with version and date.

3. Make a commit:

   ```sh
   git add lib/yabeda/activejob/version.rb CHANGELOG.md
   version=$(ruby -r ./lib/yabeda/activejob/version.rb -e "puts Gem::Version.new(Yabeda::ActiveJob::VERSION)")
   git commit --message="${version}: " --edit
   ```

4. Create annotated tag:

   ```sh
   git tag v${version} --annotate --message="${version}: " --edit --sign
   ```

5. Fill version name into subject line and (optionally) some description (list of changes will be taken from changelog and appended automatically)

6. Push it:

   ```sh
   git push --follow-tags
   ```

7. GitHub Actions will create a new release, build and push gem into RubyGems! You're done!

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

[Yabeda-sidekiq]: https://github.com/yabeda-rb/yabeda-sidekiq "Inspiration for this gem"
[yabeda]: https://github.com/yabeda-rb/yabeda
[yabeda-prometheus]: https://github.com/yabeda-rb/yabeda-prometheus
