# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## 0.2.1 - 2023-12-14

### Fixed

- Ensure http method is always uppercase. [@webmat], [#6](https://github.com/yabeda-rb/yabeda-http_requests/pull/6)

## 0.2.0 - 2021-01-25

### Fixed

- Ruby 3.0 compatibility due to keyword arguments behavior change. [@danmarcab], [#3](https://github.com/yabeda-rb/yabeda-http_requests/pull/3)
- Sniffer middleware chain execution. [@dreikanter], [#2](https://github.com/yabeda-rb/yabeda-http_requests/pull/2)

### Removed

- Support for Ruby 2.3 and 2.4 as they've reached their End of Life and Sniffer supports only 2.5 and newer anyway. [@Envek]

## 0.1.2 - 2020-03-26

### Fixed

- Error related to constant search. [@dsalahutdinov]

## 0.1.1 - 2020-03-23

### Fixed

- Memory bloat problem due to requests and responses history stored by Sniffer. [@dsalahutdinov]

## 0.1.0 - 2020-03-19

Initial release.

[@dsalahutdinov]: https://github.com/dsalahutdinov "Dmitry Salahutdinov"
[@dreikanter]: https://github.com/dreikanter "Alex Musayev"
[@danmarcab]: https://github.com/danmarcab "Daniel Marín"
[@Envek]: https://github.com/Envek "Andrey Novikov"
[@webmat]: https://github.com/webmat "Mathieu Martin"
