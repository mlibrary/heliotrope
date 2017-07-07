#!/bin/sh

echo "Setting up FITS"

# FITS
SHARED_DIR=$1

if [ -f "$SHARED_DIR/vagrant_scripts/config" ]; then
  . $SHARED_DIR/vagrant_scripts/config
fi

FITS_PATH="${DOWNLOAD_DIR}/fits-${FITS_VERSION}"

if [ ! -d $FITS_PATH ]; then
  DOWNLOAD_URL="http://projects.iq.harvard.edu/files/fits/files/fits-${FITS_VERSION}.zip"
  cd $DOWNLOAD_DIR
  if [ ! -f $DOWNLOAD_DIR/fits.zip ]; then
    curl $DOWNLOAD_URL -o fits.zip > /dev/null 2>&1
  fi
  unzip -o fits.zip > /dev/null 2>&1
  chmod a+x fits-$FITS_VERSION/*.sh
  cd
  echo "PATH=\${PATH}:$FITS_PATH" >> .bashrc
fi
