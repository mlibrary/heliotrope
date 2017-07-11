#!/bin/sh

echo "Setting up ruby environment"

# pre-requisites
PACKAGES="imagemagick libreadline-dev libyaml-dev libsqlite3-dev nodejs zlib1g-dev libsqlite3-dev nodejs redis-server"
sudo apt-get -y install $PACKAGES > /dev/null 2>&1

# ruby and the development libraries (so we can compile nokogiri, kgio, etc)
sudo apt-get -y install ruby ruby-dev > /dev/null 2>&1

# gems
GEMS="bundler rails"
gem install $GEMS --no-ri --no-rdoc > /dev/null 2>&1
