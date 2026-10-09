# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'
require 'open3'
require 'tmpdir'

RSpec.describe 'Docker app entrypoint' do # rubocop:disable RSpec/DescribeClass
  around do |example|
    Dir.mktmpdir('docker-app-spec') do |directory|
      @directory = directory
      File.write(File.join(directory, 'bundle'), <<~SH)
        #!/bin/sh
        echo "$* SKIP_TEST_DATABASE=${SKIP_TEST_DATABASE:-}" >> "$COMMAND_LOG"
        if [ "$*" = "$FAIL_COMMAND" ]; then
          echo "database task failed" >&2
          exit 1
        fi
      SH
      File.write(File.join(directory, 'mysql'), <<~SH)
        #!/bin/sh
        case "$*" in
          *information_schema.tables*)
            if [ "${FAIL_QUERY:-0}" = 1 ]; then
              echo "database query failed" >&2
              exit 1
            fi
            echo "$TABLE_COUNT"
            ;;
          *) echo 1 ;;
        esac
      SH
      File.write(File.join(directory, 'curl'), "#!/bin/sh\nexit 0\n")
      %w[bundle mysql curl].each { |command| FileUtils.chmod(0o755, File.join(directory, command)) }
      example.run
    end
  end

  def run_entrypoint(table_count:, fail_command: '', fail_query: '0')
    Open3.capture3(
      {
        'PATH' => "#{@directory}:#{ENV.fetch('PATH')}",
        'COMMAND_LOG' => File.join(@directory, 'commands'),
        'TABLE_COUNT' => table_count.to_s,
        'FAIL_COMMAND' => fail_command,
        'FAIL_QUERY' => fail_query,
        'SKIP_TEST_DATABASE' => nil
      },
      'sh', File.expand_path('../../docker/entrypoints/docker-app.sh', __dir__),
      'bundle', 'exec', 'rails', 's'
    )
  end

  def commands
    File.readlines(File.join(@directory, 'commands'), chomp: true)
  end

  it 'loads schema and seeds only for an empty database, without touching the test database' do
    _, _, status = run_entrypoint(table_count: 0)

    expect(status).to be_success
    expect(commands).to include('exec rails db:schema:load db:seed SKIP_TEST_DATABASE=1')
    expect(commands.grep(/db:migrate|db:setup/)).to be_empty
    expect(commands.last).to eq('exec rails s SKIP_TEST_DATABASE=')
  end

  it 'migrates an existing database without reloading its schema or seeds' do
    _, _, status = run_entrypoint(table_count: 10)

    expect(status).to be_success
    expect(commands).to include('exec rails db:migrate SKIP_TEST_DATABASE=')
    expect(commands.grep(/db:schema:load|db:seed|db:setup/)).to be_empty
    expect(commands.last).to eq('exec rails s SKIP_TEST_DATABASE=')
  end

  it 'stops on a migration failure without falling back to destructive setup or starting Rails' do
    _, stderr, status = run_entrypoint(table_count: 10, fail_command: 'exec rails db:migrate')

    expect(status).not_to be_success
    expect(stderr).to include('database task failed')
    expect(commands.last).to eq('exec rails db:migrate SKIP_TEST_DATABASE=')
  end

  it 'stops on a schema load failure without falling back to migrations' do
    _, stderr, status = run_entrypoint(table_count: 0, fail_command: 'exec rails db:schema:load db:seed')

    expect(status).not_to be_success
    expect(stderr).to include('database task failed')
    expect(commands.last).to eq('exec rails db:schema:load db:seed SKIP_TEST_DATABASE=1')
  end

  it 'does not treat a failed table query as an empty database' do
    _, stderr, status = run_entrypoint(table_count: 0, fail_query: '1')

    expect(status).not_to be_success
    expect(stderr).to include('database query failed')
    expect(commands.grep(/exec rails/)).to be_empty
  end
end
