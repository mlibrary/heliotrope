#!/usr/bin/env bash

echo 'BEGIN provisioning from bootstrap.sh...'
cd /vagrant
echo 'Updating package lists...'
sudo apt-get update -y > /dev/null 2>&1
echo 'Upgrading existing packages...'
sudo apt-get upgrade -y > /dev/null 2>&1
echo 'Installing libmysqlclient-dev...'
sudo apt-get install -y libmysqlclient-dev > /dev/null 2>&1
echo 'bundle install...'
bundle install
echo 'Running "bundle exec bin/setup"...'
bundle exec bin/setup
echo 'Change login directory to default vagrant share...'
echo "cd /vagrant" >> /home/vagrant/.bashrc
echo 'END provisioning from bootstrap.sh...'
