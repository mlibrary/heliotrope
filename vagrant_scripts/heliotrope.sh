#!/bin/sh

echo 'Installing libmysqlclient-dev...'
apt-get -y install libmysqlclient-dev > /dev/null 2>&1

echo 'Installing libclamav-dev...'
apt-get -y install libclamav-dev > /dev/null 2>&1

cd /vagrant

echo 'bundle install...'
bundle install

echo 'Running "bundle exec bin/setup"...'
bundle exec bin/setup

echo 'Changing login directory to default vagrant share...'
echo "cd /vagrant" >> /home/vagrant/.bashrc

echo 'END provisioning from vagrant_scripts'
