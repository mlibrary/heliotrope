#!/bin/sh
#set -euo pipefail

# wait for the database to be ready
echo "Waiting for database..."
until mysql -h db -uroot -p"${MYSQL_ROOT_PASSWORD:-helio-admin}" -e "select 1" >/dev/null 2>&1; do
	sleep 1
done

echo "Disabling foreign key checks..."
mysql -h db -uroot -p"${MYSQL_ROOT_PASSWORD:-helio-admin}" -e "SET FOREIGN_KEY_CHECKS=0;"

bundle exec rails db:setup
bundle exec rails checkpoint:migrate
bundle exec rails system_user

echo "Re-enabling foreign key checks..."
mysql -h db -uroot -p"${MYSQL_ROOT_PASSWORD:-helio-admin}" -e "SET FOREIGN_KEY_CHECKS=1;"

echo "Creating Solr core..."
curl "http://solr:8983/solr/admin/cores?action=CREATE&name=heliotrope-development"

echo "Entrypoint tasks complete."