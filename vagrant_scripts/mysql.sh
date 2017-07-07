#!/bin/sh

echo 'Installing mysql-server...'

# as of 5.7 it's difficult to get MySQL installed unattended with a blank root password
# first, use debconf-utils to set up the entry of an actual root password (also root)
echo 'mysql-server-5.7 mysql-server/root_password password root' | debconf-set-selections
echo 'mysql-server-5.7 mysql-server/root_password_again password root' | debconf-set-selections

# could preface the command with this insteal to allow critical output:
# DEBIAN_PRIORITY=critical
DEBIAN_FRONTEND=noninteractive sudo apt-get -y install mysql-server > /dev/null 2>&1

# create non-localhost root user (blank password)
mysql -h127.0.0.1 -P3306 -uroot -proot -e "create user 'root'@'10.0.2.2' identified by ''; grant all privileges on *.* to 'root'@'10.0.2.2' with grant option; flush privileges;"
# set default root user's password to blank
mysql -h127.0.0.1 -P3306 -uroot -proot -e"ALTER USER 'root'@'localhost' IDENTIFIED BY ''"

sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
service mysql restart
