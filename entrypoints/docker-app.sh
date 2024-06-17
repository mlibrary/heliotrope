bundle exec rails db:setup
mysql -u root -phelio-admin -e "GRANT CREATE, ALTER, DROP, INSERT, UPDATE, DELETE, SELECT, REFERENCES, RELOAD on *.* TO 'helio' WITH GRANT OPTION;"
bundle exec rails checkpoint:migrate
bundle exec rails system_user