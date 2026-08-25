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
	"${MYSQL_TEST_DATABASE:-heliotrope_test}" \
	-e "select 1"

# wait for solr-test to be ready
wait_for "Solr (test)" curl -sf "http://solr-test:8983/solr/admin/info/system"

# wait for Fedora (test) to be ready
wait_for "Fedora (test)" curl -sf "${FEDORA_URL:-http://fcrepo-test:8080/fcrepo/rest}"

DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:drop >/dev/null 2>&1 || true
bundle exec rails db:create >/dev/null 2>&1 || true
bundle exec rails db:environment:set RAILS_ENV=test
bundle exec rails db:schema:load

echo "Test entrypoint tasks complete."
exec "$@"
