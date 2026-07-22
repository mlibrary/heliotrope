# Copilot Instructions

## Commands
- **Run specs**: `bundle exec rspec spec/`
- **Check style**: `bundle exec rubocop`
- **Auto-fix style**: `bundle exec rubocop -A`

## Docker Commands
- Use `bin/compose` for Docker Compose in this repo.
- `bin/compose` auto-sets `DOCKER_DEFAULT_PLATFORM=linux/amd64` on macOS Apple Silicon (if not already set) and is safe to use on macOS Intel/Linux.
- **Build and run services with Docker Compose images**: `bin/compose up -d --build`
- **Stop all containers**: `bin/compose down`
- **Set up testing environment**: `bin/compose --profile test up -d db redis solr-test fcrepo-test`
- **Run all specs**: `bin/compose --profile test run --rm test`
- **Run individual specs**: `bin/compose --profile test run --rm test bundle exec rspec spec/path/to/file_spec.rb`
- **Run a system spec**: `bin/compose --profile test run --rm test bundle exec rspec spec/system/path/to_system_spec.rb`
- **To run the linter**: `bin/compose --profile test run --rm test bundle exec rubocop`


## Conventions
- Use `Time.zone.today` not `Date.today`
- Table names are plural: `counter_summaries`
- Service modules: `FeatureService::ClassName` to avoid conflicts
- Private methods should be defined below the `private` keyword. The `def` line of each private method should be indented 2 spaces relative to the `private` keyword (i.e., one standard Ruby indentation level deeper than `private`).
- Always test and lint after changes
- When suggesting test or lint commands, prefer the `bin/compose` variants unless the user explicitly indicates they are running outside Docker.
