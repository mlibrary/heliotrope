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

# wait for solr to be ready
wait_for "Solr" curl -sf "http://solr:8983/solr/admin/info/system"

# wait for Fedora to be ready
wait_for "Fedora" curl -sf "${FEDORA_URL:-http://fcrepo:8080/fcrepo/rest}"

# db:setup is idempotent on first run; fall back to db:migrate on subsequent runs
bundle exec rails db:setup 2>&1 || bundle exec rails db:migrate
bundle exec rails checkpoint:migrate
bundle exec rails system_user

echo "Entrypoint tasks complete."
exec "$@"