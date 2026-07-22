#!/bin/sh
set -eu

WAIT_TIMEOUT=${WAIT_TIMEOUT:-120}

wait_for() {
  service="$1"; shift
  elapsed=0
  echo "Waiting for ${service}..."
  until "$@" >/dev/null 2>&1; do
    elapsed=$((elapsed + 1))
    if [ "$elapsed" -ge "$WAIT_TIMEOUT" ]; then
      echo "ERROR: Timed out waiting for ${service} after ${WAIT_TIMEOUT}s" >&2
      exit 1
    fi
    sleep 1
  done
}

# Ensure gems are installed (gem_cache volume may be stale after --build)
bundle install

# wait for the database to be ready
wait_for "database" mysql --protocol=tcp \
	--skip-ssl \
	-h "${MYSQL_HOST:-db}" \
	-u"${MYSQL_USER:-helio}" \
	-p"${MYSQL_PASSWORD:-helio}" \
	"${MYSQL_DATABASE:-heliotrope_development}" \
	-e "select 1"

# wait for redis to be ready
wait_for "Redis" bundle exec ruby -r redis -e 'exit(Redis.new(host: ENV.fetch("REDIS_HOST", "redis"), port: Integer(ENV.fetch("REDIS_PORT", "6379")), thread_safe: true).ping == "PONG" ? 0 : 1)'

echo "Resque entrypoint tasks complete."
exec "$@"
