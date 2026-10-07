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

database_query() {
  mysql --protocol=tcp --skip-ssl --batch --skip-column-names \
    -h "${MYSQL_HOST:-db}" \
    -u"${MYSQL_USER:-helio}" \
    -p"${MYSQL_PASSWORD:-helio}" \
    "${MYSQL_DATABASE:-heliotrope_development}" \
    -e "$1"
}

# wait for the database to be ready
wait_for "database" database_query "select 1"

# wait for solr to be ready
wait_for "Solr" curl -sf "http://solr:8983/solr/admin/info/system"

# wait for Fedora to be ready
wait_for "Fedora" curl -sf "${FEDORA_URL:-http://fcrepo:8080/fcrepo/rest}"

# Loading the schema replaces tables, so only bootstrap a completely empty database.
table_count=$(database_query "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE()")
if [ "$table_count" -eq 0 ]; then
  SKIP_TEST_DATABASE=1 bundle exec rails db:schema:load db:seed
else
  bundle exec rails db:migrate
fi
bundle exec rails checkpoint:migrate
bundle exec rails system_user
bundle exec rails jekyll:deploy

echo "Entrypoint tasks complete."
exec "$@"