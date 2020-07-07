###
# BASICS
###

SHARED_DIR=$1

if [ -f "$SHARED_DIR/vagrant_scripts/config" ]; then
  . $SHARED_DIR/vagrant_scripts/config
fi

cd

echo 'BEGIN provisioning from bootstrap.sh...'

# Update
echo 'Updating package lists...'
DEBIAN_FRONTEND=noninteractive sudo apt-get -y update > /dev/null 2>&1
echo 'Upgrading existing packages...'
DEBIAN_FRONTEND=noninteractive sudo apt-get -y upgrade > /dev/null 2>&1

# SSH
sudo apt-get -y install openssh-server > /dev/null 2>&1

# Build tools
sudo apt-get -y install build-essential > /dev/null 2>&1

# Git vim
sudo apt-get -y install git vim > /dev/null 2>&1

# Wget, curl and unzip
sudo apt-get -y install wget curl unzip > /dev/null 2>&1

# FFmpeg
sudo apt-get -y install ffmpeg > /dev/null 2>&1
