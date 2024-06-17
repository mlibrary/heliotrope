#!/bin/sh

mysql -u root -phelio-admin -e "GRANT CREATE, ALTER, DROP, INSERT, UPDATE, DELETE, SELECT, REFERENCES, RELOAD on *.* TO 'helio' WITH GRANT OPTION;"
bin/setup
bundle exec rails checkpoint:migrate
bundle exec rails system_user
#curl "$SOLR_URL/solr/admin/cores?action=CREATE&name=heliotrope-development"