#!/bin/bash

if [ ! -f config/database.yml ]; then
    cp config/database.yml.sample config/database.yml
fi
mysql -u root -phelio-admin -e "GRANT CREATE, ALTER, DROP, INSERT, UPDATE, DELETE, SELECT, REFERENCES, RELOAD on *.* TO 'helio' WITH GRANT OPTION;"
mysql -u root -phelio-admin -e "SET character_set_server = 'utf8mb4';"
mysql -u root -phelio-admin -e "SET collation_server = 'utf8mb4_unicode_ci';"
mysql -u root -phelio-admin -e "FLUSH PRIVILEGES;"

bundle exec rails db:setup
bundle exec rails checkpoint:migrate
bundle exec rails system_user