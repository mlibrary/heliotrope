<a href="https://amplifr.com/?utm_source=yabeda-http_requests">
  <img width="100" height="140" align="right"
    alt="Sponsored by Amplifr" src="https://amplifr-direct.s3-eu-west-1.amazonaws.com/social_images/image/37b580d9-3668-4005-8d5a-137de3a3e77c.png" />
</a>

# ![Yabeda::HttpRequests](./yabeda-http_requests-logo.png)

Built-in metrics for external services HTTP calls! This gem is a Part of the [yabeda](https://github.com/yabeda-rb/yabeda) suite.

Read [introduction article on dev.to](https://dev.to/dsalahutdinov/monitoring-external-services-with-prometheus-and-grafana-5eh6).

## Metrics

Works as the Puma plugin and provides following metrics:
 - `http_request_total` - the number of external HTTP request attempts (by host, port, method)
 - `http_response_total` - the number of made external HTTP requeusts (by host, port, method, status)
 - `http_response_duration` - the histogram of response duration (by host, port, method, status)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'yabeda-http_requests'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install yabeda-http_requests

## Usage

After plugin the gem, you just have to set up metrics exporting with [yabeda-prometheus](https://github.com/yabeda-rb/yabeda-prometheus) gem.

The metrics page will look like this:

```
# TYPE http_requests_total_count counter
# HELP http_requests_total_count A counter of the total number of external HTTP requests.
http_request_total{host="twitter.com",port="443",method="GET",query="/dsalahutdinov1"} 149.0
http_request_total{host="dev.to",port="443",method="GET",query="/amplifr"} 145.0
...
```

To simple set up Grafana, try the [sample dashboard](https://github.com/yabeda-rb/yabeda-http_requests/blob/master/example/grafana/provisioning/dashboards/yabeda-http_requests.json).

## Sample application

Sample application aims to show how Ruby web-application, this gem and Prometheus/Grafana work togather.
Get into `example` directory and run docker compose:

```sh
$ cd example
$ docker-compose up
```

After docker image builds and all the services get up, you can browse application endpoints:
 - Ruby web-application runs on [http://localhost:9292/](http://localhost:9292/). Everytime you request page, it schedules random web-scrapping job into sidekiq.
 - Sidekiq exposes prometheus metrics on [http://localhost:9394/metrics](http://localhost:9394/metrics). This endpoint is scrapped by prometheus exporter every 5 seconds.
 - Grafana runs on [http://localhost:3000/](http://localhost:3000/). Use `admin/foobar` as login and password to get in. Grafana already has specific dashboard with data visualisation.

Follow the [yabeda-external-http-requests](http://localhost:3000/d/OGd-oEXWz/yabeda-external-http-requests?orgId=1&refresh=5s) dashboard in Grafana.
Finally, after a couple of minutes when data collected you will see the following:
![Monitor external HTTP calls with Grafana](docs/dashboard.png)

## Development with Docker

Get local development environment working and tests running is very easy with docker-compose:
```bash
docker-compose run app bundle
docker-compose run app bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yabeda-rb/yabeda-http_requests.

### Releasing

1. Bump version number in `lib/yabeda/http_requests/version.rb`

   In case of pre-releases keep in mind [rubygems/rubygems#3086](https://github.com/rubygems/rubygems/issues/3086) and check version with command like `Gem::Version.new(Yabeda::VERSION).to_s`

2. Fill `CHANGELOG.md` with missing changes, add header with version and date.

3. Make a commit:

   ```sh
   git add lib/yabeda/http_requests/version.rb CHANGELOG.md
   version=$(ruby -r ./lib/yabeda/http_requests/version.rb -e "puts Gem::Version.new(Yabeda::HttpRequests::VERSION)")
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
