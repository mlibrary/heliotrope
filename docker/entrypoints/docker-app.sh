#!/bin/sh
#set -euo pipefail

# wait for the database to be ready
echo "Waiting for database..."
until mysql -h "${MYSQL_HOST:-db}" -uroot -p"${MYSQL_ROOT_PASSWORD:-helio-admin}" -e "select 1" >/dev/null 2>&1; do
	sleep 1
done

# wait for solr to be ready
echo "Waiting for Solr..."
until curl -sf "http://solr:8983/solr/admin/info/system" >/dev/null 2>&1; do
	sleep 1
done

# db:setup is idempotent on first run; fall back to db:migrate on subsequent runs
bundle exec rails db:setup 2>&1 || bundle exec rails db:migrate
bundle exec rails checkpoint:migrate
bundle exec rails system_user

echo "Entrypoint tasks complete."
exec "$@"